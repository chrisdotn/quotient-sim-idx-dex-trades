// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./NativeTokenResolver.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract BancorCarbonListener is BancorController$OnTokensTradedEvent, NativeTokenResolver, IDexListener {
    function BancorController$onTokensTradedEvent(
        EventContext memory ctx,
        BancorController$TokensTradedEventParams memory params
    ) external override {
        (string memory sourceTokenName, string memory sourceTokenSymbol, uint256 sourceTokenDecimals) = params
            .sourceToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(params.sourceToken);
        (string memory targetTokenName, string memory targetTokenSymbol, uint256 targetTokenDecimals) = params
            .targetToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(params.targetToken);
        DexTradeData memory trade;
        trade.dex = "BancorCarbon";
        trade.fromToken = params.sourceToken;
        trade.fromTokenAmt = params.sourceAmount;
        trade.fromTokenName = sourceTokenName;
        trade.fromTokenSymbol = sourceTokenSymbol;
        trade.fromTokenDecimals = uint8(sourceTokenDecimals);
        trade.toToken = params.targetToken;
        trade.toTokenAmt = params.targetAmount;
        trade.toTokenName = targetTokenName;
        trade.toTokenSymbol = targetTokenSymbol;
        trade.toTokenDecimals = uint8(targetTokenDecimals);
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.trader;
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
