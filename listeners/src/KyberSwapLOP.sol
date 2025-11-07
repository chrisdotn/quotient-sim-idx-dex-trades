// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract KyberSwapLOPListener is
    DSLOProtocol$OnFillOrderToFunction,
    LimitOrderProtocol$OnFillOrderRfqToFunction,
    LimitOrderProtocol$OnFillOrderFunction,
    LimitOrderProtocol$OnFillBatchOrdersToFunction,
    LimitOrderProtocol$OnFillOrderToWithPermitFunction,
    IDexListener
{
    function DSLOProtocol$onFillOrderToFunction(
        FunctionContext memory ctx,
        DSLOProtocol$FillOrderToFunctionInputs memory inputs,
        DSLOProtocol$FillOrderToFunctionOutputs memory outputs
    ) external override {
        address maker = inputs.params.order.maker;
        address makerAsset = inputs.params.order.makerAsset;
        address takerAsset = inputs.params.order.takerAsset;
        address taker = inputs.params.target;

        emitMakerTakerTrades(
            makerAsset,
            takerAsset,
            maker,
            taker,
            outputs.outArg0,
            outputs.outArg1,
            ctx.txn.call.callee(),
            ctx.txn.hash()
        );
    }

    function LimitOrderProtocol$onFillOrderRfqToFunction(
        FunctionContext memory ctx,
        LimitOrderProtocol$FillOrderRfqToFunctionInputs memory inputs,
        LimitOrderProtocol$FillOrderRfqToFunctionOutputs memory outputs
    ) external override {
        address maker = inputs.order.maker;
        address makerAsset = inputs.order.makerAsset;
        address takerAsset = inputs.order.takerAsset;
        address taker = inputs.target;

        emitMakerTakerTrades(
            makerAsset,
            takerAsset,
            maker,
            taker,
            outputs.outArg0,
            outputs.outArg1,
            ctx.txn.call.callee(),
            ctx.txn.hash()
        );
    }

    function LimitOrderProtocol$onFillOrderFunction(
        FunctionContext memory ctx,
        LimitOrderProtocol$FillOrderFunctionInputs memory inputs,
        LimitOrderProtocol$FillOrderFunctionOutputs memory outputs
    ) external override {
        address maker = inputs.order.maker;
        address makerAsset = inputs.order.makerAsset;
        address takerAsset = inputs.order.takerAsset;

        emitMakerTakerTrades(
            makerAsset,
            takerAsset,
            maker,
            ctx.txn.call.caller(),
            outputs.outArg0,
            outputs.outArg1,
            ctx.txn.call.callee(),
            ctx.txn.hash()
        );
    }

    function LimitOrderProtocol$onFillBatchOrdersToFunction(
        FunctionContext memory ctx,
        LimitOrderProtocol$FillBatchOrdersToFunctionInputs memory inputs,
        LimitOrderProtocol$FillBatchOrdersToFunctionOutputs memory outputs
    ) external override {
        for (uint256 i = 0; i < inputs.params.orders.length; i++) {
            address maker = inputs.params.orders[i].maker;
            address makerAsset = inputs.params.orders[i].makerAsset;
            address takerAsset = inputs.params.orders[i].takerAsset;
            address taker = inputs.params.target;

            emitMakerTakerTrades(
                makerAsset,
                takerAsset,
                maker,
                taker,
                outputs.outArg0,
                outputs.outArg1,
                ctx.txn.call.callee(),
                ctx.txn.hash()
            );
        }
    }

    function LimitOrderProtocol$onFillOrderToWithPermitFunction(
        FunctionContext memory ctx,
        LimitOrderProtocol$FillOrderToWithPermitFunctionInputs memory inputs,
        LimitOrderProtocol$FillOrderToWithPermitFunctionOutputs memory outputs
    ) external override {
        address maker = inputs.order.maker;
        address makerAsset = inputs.order.makerAsset;
        address takerAsset = inputs.order.takerAsset;
        address taker = inputs.target;

        emitMakerTakerTrades(
            makerAsset,
            takerAsset,
            maker,
            taker,
            outputs.outArg0,
            outputs.outArg1,
            ctx.txn.call.callee(),
            ctx.txn.hash()
        );
    }

    function emitMakerTakerTrades(
        address makingToken,
        address takingToken,
        address maker,
        address,
        uint256 makingAmount,
        uint256 takingAmount,
        address platformContract,
        bytes32 txnHash
    ) internal {
        (string memory makingTokenName, string memory makingTokenSymbol, uint256 makingTokenDecimals) =
            getMetadata(makingToken);
        (string memory takingTokenName, string memory takingTokenSymbol, uint256 takingTokenDecimals) =
            getMetadata(takingToken);

        DexTradeData memory trade;
        trade.dex = "1InchLOPV4";
        trade.fromToken = makingToken;
        trade.fromTokenAmt = makingAmount;
        trade.fromTokenName = makingTokenName;
        trade.fromTokenSymbol = makingTokenSymbol;
        trade.fromTokenDecimals = uint8(makingTokenDecimals);
        trade.toToken = takingToken;
        trade.toTokenAmt = takingAmount;
        trade.toTokenName = takingTokenName;
        trade.toTokenSymbol = takingTokenSymbol;
        trade.toTokenDecimals = uint8(takingTokenDecimals);
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = txnHash;
        trade.txnOriginator = tx.origin;
        trade.recipient = maker;
        trade.liquidityPool = platformContract;

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
