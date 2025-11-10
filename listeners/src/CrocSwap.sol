// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./NativeTokenResolver.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract CrocSwapListener is HotProxy$OnUserCmdFunction, NativeTokenResolver, IDexListener {
    function HotProxy$onUserCmdFunction(
        FunctionContext memory ctx,
        HotProxy$UserCmdFunctionInputs memory inputs,
        HotProxy$UserCmdFunctionOutputs memory outputs
    ) external override {
        (address token0, address token1,, bool isBuy,,,,,,) =
            abi.decode(inputs.input, (address, address, uint256, bool, bool, uint128, uint16, uint128, uint128, uint8));

        uint128 token0Amt = outputs.outArg0 < 0 ? uint128(-outputs.outArg0) : uint128(outputs.outArg0);
        uint128 token1Amt = outputs.outArg1 < 0 ? uint128(-outputs.outArg1) : uint128(outputs.outArg1);

        (string memory token0Name, string memory token0Symbol, uint256 token0Decimals) = token0 == address(0)
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(token0);
        (string memory token1Name, string memory token1Symbol, uint256 token1Decimals) = token1 == address(0)
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(token1);

        DexTradeData memory trade;
        trade.dex = "CrocSwap";
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = tx.origin;
        trade.liquidityPool = ctx.txn.call.callee();

        if (isBuy) {
            trade.fromToken = token0;
            trade.fromTokenAmt = token0Amt;
            trade.fromTokenName = token0Name;
            trade.fromTokenSymbol = token0Symbol;
            trade.fromTokenDecimals = uint8(token0Decimals);
            trade.toToken = token1;
            trade.toTokenAmt = token1Amt;
            trade.toTokenName = token1Name;
            trade.toTokenSymbol = token1Symbol;
            trade.toTokenDecimals = uint8(token1Decimals);
        } else {
            trade.fromToken = token1;
            trade.fromTokenAmt = token1Amt;
            trade.fromTokenName = token1Name;
            trade.fromTokenSymbol = token1Symbol;
            trade.fromTokenDecimals = uint8(token1Decimals);
            trade.toToken = token0;
            trade.toTokenAmt = token0Amt;
            trade.toTokenName = token0Name;
            trade.toTokenSymbol = token0Symbol;
            trade.toTokenDecimals = uint8(token0Decimals);
        }

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
}
