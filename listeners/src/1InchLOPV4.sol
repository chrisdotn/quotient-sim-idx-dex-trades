// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./libs/1inch/AddressLib.sol";
import "./1inchUtils.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract OneInchLOPV4Listener is
    AggregationRouterV6$OnFillOrderFunction,
    AggregationRouterV6$OnFillOrderArgsFunction,
    AggregationRouterV6$OnFillContractOrderArgsFunction,
    AggregationRouterV6$OnFillContractOrderFunction,
    OneInchUtils,
    IDexListener
{
    function AggregationRouterV6$onFillContractOrderFunction(
        FunctionContext memory ctx,
        AggregationRouterV6$FillContractOrderFunctionInputs memory inputs,
        AggregationRouterV6$FillContractOrderFunctionOutputs memory outputs
    ) external override {
        address maker = AddressLib.get(Address.wrap(inputs.order.maker));
        address makerAsset = AddressLib.get(Address.wrap(inputs.order.makerAsset));
        address takerAsset = AddressLib.get(Address.wrap(inputs.order.takerAsset));

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

    function AggregationRouterV6$onFillContractOrderArgsFunction(
        FunctionContext memory ctx,
        AggregationRouterV6$FillContractOrderArgsFunctionInputs memory inputs,
        AggregationRouterV6$FillContractOrderArgsFunctionOutputs memory outputs
    ) external override {
        address makerAsset;
        address takerAsset;
        (address target, bytes memory extension,) = parseArgs(TakerTraits.wrap(inputs.takerTraits), inputs.args);
        if (extension.length > 0) {
            makerAsset = getMakerAssetFromSuffix(extension);
            takerAsset = getTakerAssetFromSuffix(extension);
            if (makerAsset == address(0)) makerAsset = AddressLib.get(Address.wrap(inputs.order.makerAsset));
            if (takerAsset == address(0)) takerAsset = AddressLib.get(Address.wrap(inputs.order.takerAsset));
        } else {
            makerAsset = AddressLib.get(Address.wrap(inputs.order.makerAsset));
            takerAsset = AddressLib.get(Address.wrap(inputs.order.takerAsset));
        }
        emitMakerTakerTrades(
            makerAsset,
            takerAsset,
            AddressLib.get(Address.wrap(inputs.order.maker)),
            target == address(0) ? ctx.txn.call.caller() : target,
            outputs.outArg0,
            outputs.outArg1,
            ctx.txn.call.callee(),
            ctx.txn.hash()
        );
    }

    function AggregationRouterV6$onFillOrderArgsFunction(
        FunctionContext memory ctx,
        AggregationRouterV6$FillOrderArgsFunctionInputs memory inputs,
        AggregationRouterV6$FillOrderArgsFunctionOutputs memory outputs
    ) external override {
        address makerAsset;
        address takerAsset;
        (address target, bytes memory extension,) = parseArgs(TakerTraits.wrap(inputs.takerTraits), inputs.args);
        if (extension.length > 0) {
            makerAsset = getMakerAssetFromSuffix(extension);
            takerAsset = getTakerAssetFromSuffix(extension);
            if (makerAsset == address(0)) makerAsset = AddressLib.get(Address.wrap(inputs.order.makerAsset));
            if (takerAsset == address(0)) takerAsset = AddressLib.get(Address.wrap(inputs.order.takerAsset));
        } else {
            makerAsset = AddressLib.get(Address.wrap(inputs.order.makerAsset));
            takerAsset = AddressLib.get(Address.wrap(inputs.order.takerAsset));
        }
        emitMakerTakerTrades(
            makerAsset,
            takerAsset,
            AddressLib.get(Address.wrap(inputs.order.maker)),
            target == address(0) ? ctx.txn.call.caller() : target,
            outputs.outArg0,
            outputs.outArg1,
            ctx.txn.call.callee(),
            ctx.txn.hash()
        );
    }

    function AggregationRouterV6$onFillOrderFunction(
        FunctionContext memory ctx,
        AggregationRouterV6$FillOrderFunctionInputs memory inputs,
        AggregationRouterV6$FillOrderFunctionOutputs memory outputs
    ) external override {
        address maker = AddressLib.get(Address.wrap(inputs.order.maker));
        address makerAsset = AddressLib.get(Address.wrap(inputs.order.makerAsset));
        address takerAsset = AddressLib.get(Address.wrap(inputs.order.takerAsset));

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
