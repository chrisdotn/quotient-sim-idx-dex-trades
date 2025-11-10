// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import {getMetadata} from "./utils/ERC20Metadata.sol";
import "./types/DexTrades.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "./libs/UniswapV4/BalanceDelta.sol";
import {NativeTokenResolver} from "./NativeTokenResolver.sol";
import {EkuboPoolKey} from "./types/Ekubo/PoolKey.sol";
import {SqrtRatio} from "./types/Ekubo/SqrtRatio.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract EkuboListener is
    EkuboCore$OnSwap611415377Function,
    EkuboCore$PreLockFunction,
    EkuboCore$OnLockFunction,
    NativeTokenResolver,
    IDexListener
{
    address internal recipient;

    function EkuboCore$onLockFunction(FunctionContext memory) external override {
        recipient = address(0);
    }

    function EkuboCore$preLockFunction(PreFunctionContext memory ctx) external override {
        if (ctx.txn.call.callData()[4] != bytes1(0x00)) {
            // not a swap -- bail out early
            return;
        }
        (,,,,,,,, recipient) = this.decodeSwapData(ctx.txn.call.callData());
    }

    function EkuboCore$onSwap611415377Function(
        FunctionContext memory ctx,
        EkuboCore$Swap611415377FunctionInputs memory inputs,
        EkuboCore$Swap611415377FunctionOutputs memory outputs
    ) external override {
        (string memory token0Symbol, string memory token0Name, uint256 token0Decimals) = inputs.poolKey.token0
            == address(0)
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(inputs.poolKey.token0);
        (string memory token1Symbol, string memory token1Name, uint256 token1Decimals) = inputs.poolKey.token1
            == address(0)
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(inputs.poolKey.token1);
        DexTradeData memory trade;
        trade.chainId = uint64(block.chainid);
        trade.transactionHash = ctx.txn.hash();
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = uint64(block.timestamp);
        trade.txnOriginator = tx.origin;
        trade.recipient = recipient == address(0) ? ctx.txn.call.caller() : recipient;
        trade.liquidityPool = ctx.txn.call.callee();
        trade.dex = "Ekubo";

        if (!inputs.isToken1) {
            trade.fromToken = inputs.poolKey.token0;
            trade.fromTokenAmt = outputs.delta0 < 0 ? uint128(-outputs.delta0) : uint128(outputs.delta0);
            trade.fromTokenSymbol = token0Symbol;
            trade.fromTokenName = token0Name;
            trade.fromTokenDecimals = uint8(token0Decimals);
            trade.toToken = inputs.poolKey.token1;
            trade.toTokenAmt = outputs.delta1 < 0 ? uint128(-outputs.delta1) : uint128(outputs.delta1);
            trade.toTokenSymbol = token1Symbol;
            trade.toTokenName = token1Name;
            trade.toTokenDecimals = uint8(token1Decimals);
        } else {
            trade.fromToken = inputs.poolKey.token1;
            trade.fromTokenAmt = outputs.delta1 < 0 ? uint128(-outputs.delta1) : uint128(outputs.delta1);
            trade.fromTokenSymbol = token1Symbol;
            trade.fromTokenName = token1Name;
            trade.fromTokenDecimals = uint8(token1Decimals);
            trade.toToken = inputs.poolKey.token0;
            trade.toTokenAmt = outputs.delta0 < 0 ? uint128(-outputs.delta0) : uint128(outputs.delta0);
            trade.toTokenSymbol = token0Symbol;
            trade.toTokenName = token0Name;
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

    function decodeSwapData(bytes calldata data)
        external
        pure
        returns (bytes1, address, EkuboPoolKey memory, bool, int128, SqrtRatio, uint256, int256, address)
    {
        return abi.decode(data[4:], (bytes1, address, EkuboPoolKey, bool, int128, SqrtRatio, uint256, int256, address));
    }
}
