// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import {OrderQuoter} from "./OrderQuoter.sol";
import {ResolvedOrder, InputToken, OutputToken} from "./interfaces/UniswapX/ReactorStructs.sol";
import {IReactor} from "./interfaces/UniswapX/IReactor.sol";
import {getMetadata} from "./utils/ERC20Metadata.sol";
import {FeeInjector} from "./libs/UniswapX/FeeInjector.sol";
import "./types/DexTrades.sol";
import "./interfaces/IDexListener.sol";

contract UniswapXListener is
    OrderQuoter,
    Reactor$PreExecuteFunction,
    Reactor$PreExecuteBatchFunction,
    Reactor$PreExecuteBatchWithCallbackFunction,
    Reactor$PreExecuteWithCallbackFunction,
    IDexListener
{
    bytes32 internal txnHash;

    function Reactor$preExecuteFunction(PreFunctionContext memory ctx, Reactor$ExecuteFunctionInputs memory inputs)
        external
        override
    {
        txnHash = ctx.txn.hash();
        ResolvedOrder memory order = this.quote(inputs.order.order, inputs.order.sig);
        FeeInjector._injectFees(order, IReactor(order.info.reactor).feeController());
        emitTradesFromOrder(order, ctx.txn.call.caller());
    }

    function Reactor$preExecuteBatchFunction(
        PreFunctionContext memory ctx,
        Reactor$ExecuteBatchFunctionInputs memory inputs
    ) external override {
        txnHash = ctx.txn.hash();
        for (uint256 i = 0; i < inputs.orders.length; i++) {
            ResolvedOrder memory order = this.quote(inputs.orders[i].order, inputs.orders[i].sig);
            FeeInjector._injectFees(order, IReactor(order.info.reactor).feeController());
            emitTradesFromOrder(order, ctx.txn.call.caller());
        }
    }

    function Reactor$preExecuteBatchWithCallbackFunction(
        PreFunctionContext memory ctx,
        Reactor$ExecuteBatchWithCallbackFunctionInputs memory inputs
    ) external override {
        txnHash = ctx.txn.hash();
        for (uint256 i = 0; i < inputs.orders.length; i++) {
            ResolvedOrder memory order = this.quote(inputs.orders[i].order, inputs.orders[i].sig);
            FeeInjector._injectFees(order, IReactor(order.info.reactor).feeController());
            emitTradesFromOrder(order, ctx.txn.call.caller());
        }
    }

    function Reactor$preExecuteWithCallbackFunction(
        PreFunctionContext memory ctx,
        Reactor$ExecuteWithCallbackFunctionInputs memory inputs
    ) external override {
        if (ctx.txn.call.caller() != address(this)) {
            txnHash = ctx.txn.hash();
            ResolvedOrder memory order = this.quote(inputs.order.order, inputs.order.sig);
            FeeInjector._injectFees(order, IReactor(order.info.reactor).feeController());
            emitTradesFromOrder(order, ctx.txn.call.caller());
        }
    }

    function emitUniswapXTrade(
        address makingToken,
        address takingToken,
        address maker,
        address,
        uint256 makingAmount,
        uint256 takingAmount,
        address platformContract
    ) internal {
        (string memory makingTokenSymbol, string memory makingTokenName, uint256 makingTokenDecimals) =
            makingToken == address(0) ? ("ETH", "Ether", 18) : getMetadata(makingToken);
        (string memory takingTokenSymbol, string memory takingTokenName, uint256 takingTokenDecimals) =
            takingToken == address(0) ? ("ETH", "Ether", 18) : getMetadata(takingToken);

        DexTradeData memory trade = DexTradeData({
            chainId: uint64(block.chainid),
            blockNumber: blockNumber(),
            blockTimestamp: block.timestamp,
            transactionHash: txnHash,
            dex: "UniswapX",
            fromToken: makingToken,
            fromTokenAmt: makingAmount,
            fromTokenName: makingTokenName,
            fromTokenSymbol: makingTokenSymbol,
            fromTokenDecimals: uint8(makingTokenDecimals),
            toToken: takingToken,
            toTokenAmt: takingAmount,
            toTokenName: takingTokenName,
            toTokenSymbol: takingTokenSymbol,
            toTokenDecimals: uint8(takingTokenDecimals),
            txnOriginator: tx.origin,
            recipient: maker,
            liquidityPool: platformContract,
            usdcValue: 0
        });
        emit DexTrade(trade);
    }

    function emitTradesFromOrder(ResolvedOrder memory order, address taker) internal {
        (InputToken memory input, OutputToken memory output) = getIoTokensFromOrder(order);
        emitUniswapXTrade(
            input.token, output.token, output.recipient, taker, input.amount, output.amount, address(order.info.reactor)
        );
    }

    function getIoTokensFromOrder(ResolvedOrder memory order)
        internal
        pure
        returns (InputToken memory input, OutputToken memory output)
    {
        input = order.input;
        uint256 outputIndex;
        uint256 outputAmount;
        unchecked {
            for (uint256 i = 0; i < order.outputs.length; i++) {
                if (order.outputs[i].recipient == order.info.swapper) return (input, order.outputs[i]);
                if (order.outputs[i].amount > outputAmount) outputIndex = i;
            }
        }
        output = order.outputs[outputIndex];
        return (input, output);
    }
}
