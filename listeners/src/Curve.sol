// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract CurveListener is
    OldTokenExchange$OnTokenExchangeEvent,
    TokenExchange$OnTokenExchangeEvent,
    DexUtils,
    IDexListener
{
    function OldTokenExchange$onTokenExchangeEvent(
        EventContext memory ctx,
        OldTokenExchange$TokenExchangeEventParams memory params
    ) external override {
        (address tokenTo, address tokenFrom) =
            DexUtils.getCurvePoolToFromTokens(ctx.txn.call.callee(), params.bought_id, params.sold_id);
        (string memory sourceTokenName, string memory sourceTokenSymbol, uint256 sourceTokenDecimals) =
            getMetadata(tokenFrom);
        (string memory targetTokenName, string memory targetTokenSymbol, uint256 targetTokenDecimals) =
            getMetadata(tokenTo);
        DexTradeData memory trade;
        trade.dex = "Curve";
        trade.fromToken = tokenFrom;
        trade.fromTokenAmt = params.tokens_sold;
        trade.fromTokenName = sourceTokenName;
        trade.fromTokenSymbol = sourceTokenSymbol;
        trade.fromTokenDecimals = uint8(sourceTokenDecimals);
        trade.toToken = tokenTo;
        trade.toTokenAmt = params.tokens_bought;
        trade.toTokenName = targetTokenName;
        trade.toTokenSymbol = targetTokenSymbol;
        trade.toTokenDecimals = uint8(targetTokenDecimals);
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.buyer;
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

    function TokenExchange$onTokenExchangeEvent(
        EventContext memory ctx,
        TokenExchange$TokenExchangeEventParams memory params
    ) external override {
        (address tokenTo, address tokenFrom) = getCurvePoolToFromTokens(
            ctx.txn.call.callee(), int128(uint128(params.bought_id)), int128(uint128(params.sold_id))
        );
        (string memory sourceTokenName, string memory sourceTokenSymbol, uint256 sourceTokenDecimals) =
            getMetadata(tokenFrom);
        (string memory targetTokenName, string memory targetTokenSymbol, uint256 targetTokenDecimals) =
            getMetadata(tokenTo);
        DexTradeData memory trade;
        trade.dex = "Curve";
        trade.fromToken = tokenFrom;
        trade.fromTokenAmt = params.tokens_sold;
        trade.fromTokenName = sourceTokenName;
        trade.fromTokenSymbol = sourceTokenSymbol;
        trade.fromTokenDecimals = uint8(sourceTokenDecimals);
        trade.toToken = tokenTo;
        trade.toTokenAmt = params.tokens_bought;
        trade.toTokenName = targetTokenName;
        trade.toTokenSymbol = targetTokenSymbol;
        trade.toTokenDecimals = uint8(targetTokenDecimals);
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.buyer;
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
