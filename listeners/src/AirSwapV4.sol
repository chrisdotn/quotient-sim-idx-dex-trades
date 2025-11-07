// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract AirSwapV4Listener is AirSwapV4$OnSwapErc20Event, DexUtils, IDexListener {
    function AirSwapV4$onSwapErc20Event(EventContext memory ctx, AirSwapV4$SwapErc20EventParams memory params)
        external
        override
    {
        (string memory fromTokenName, string memory fromTokenSymbol, uint256 fromTokenDecimals) =
            getMetadata(params.signerToken);
        (string memory toTokenName, string memory toTokenSymbol, uint256 toTokenDecimals) =
            getMetadata(params.senderToken);
        DexTradeData memory trade;

        trade.fromToken = params.signerToken;
        trade.fromTokenName = fromTokenName;
        trade.fromTokenSymbol = fromTokenSymbol;
        trade.fromTokenDecimals = uint8(fromTokenDecimals);
        trade.toToken = params.senderToken;
        trade.toTokenName = toTokenName;
        trade.toTokenSymbol = toTokenSymbol;
        trade.toTokenDecimals = uint8(toTokenDecimals);
        trade.dex = "AirSwapV4";
        trade.fromTokenAmt = params.signerAmount;
        trade.toTokenAmt = params.senderAmount;
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.signerWallet;
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
}
