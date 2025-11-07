// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./interfaces/IDexListener.sol";
import "./libs/Renegade/RenegadePostcardBuffer.sol";
import "./libs/Renegade/ProtobufLib.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract RenegadeListener is DarkPool$OnProcessAtomicMatchSettleWithReceiverFunction, IDexListener {
    function DarkPool$onProcessAtomicMatchSettleWithReceiverFunction(
        FunctionContext memory ctx,
        DarkPool$ProcessAtomicMatchSettleWithReceiverFunctionInputs memory inputs,
        DarkPool$ProcessAtomicMatchSettleWithReceiverFunctionOutputs memory outputs
    ) external override {
        (bool success,, ExternalMatchResult memory result) =
            this._getNextExternalMatchResult(uint64(0), inputs.validMatchSettleAtomicStatement);
        if (!success) {
            return;
        }
        (address tokenIn, address tokenOut) = result.direction == ExternalMatchDirection.InternalPartyBuy
            ? (result.baseMint, result.quoteMint)
            : (result.quoteMint, result.baseMint);
        (string memory tokenInName, string memory tokenInSymbol, uint256 tokenInDecimals) = getMetadata(tokenIn);
        (string memory tokenOutName, string memory tokenOutSymbol, uint256 tokenOutDecimals) = getMetadata(tokenOut);
        DexTradeData memory trade;

        trade.fromToken = tokenIn;
        trade.fromTokenName = tokenInName;
        trade.fromTokenSymbol = tokenInSymbol;
        trade.fromTokenDecimals = uint8(tokenInDecimals);
        trade.toToken = tokenOut;
        trade.toTokenName = tokenOutName;
        trade.toTokenSymbol = tokenOutSymbol;
        trade.toTokenDecimals = uint8(tokenOutDecimals);
        trade.dex = "Renegade";
        trade.fromTokenAmt =
            result.direction == ExternalMatchDirection.InternalPartyBuy ? result.baseAmount : result.quoteAmount;
        trade.toTokenAmt = outputs.amountOut;
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = inputs.receiver;
        trade.liquidityPool = ctx.txn.call.callee();

        // fetch usdc value with CL oracle
        ChainlinkPriceFetcher chainlinkPriceFetcher = new ChainlinkPriceFetcher();
        (uint256 usdcPrice, uint256 usdcDecimals) = chainlinkPriceFetcher.getChainlinkDataFeedLatestAnswer(trade.fromToken);
        if (usdcPrice != 0) {
            trade.usdcValue = trade.fromTokenAmt * usdcPrice / 10 ** usdcDecimals;
        } else {
            // try toToken
            (usdcPrice, usdcDecimals) = chainlinkPriceFetcher.getChainlinkDataFeedLatestAnswer(trade.toToken);
            if (usdcPrice != 0) {
                trade.usdcValue = trade.toTokenAmt * usdcPrice / 10 ** usdcDecimals;
            }
        }

        emit DexTrade(trade);
    }

    function _getNextExternalMatchResult(uint64 pos, bytes calldata data)
        external
        pure
        returns (bool, uint64, ExternalMatchResult memory)
    {
        return RenegadePostcardBuffer.getNextExternalMatchResult(pos, data);
    }
}
