// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import {getMetadata} from "./utils/ERC20Metadata.sol";
import "./types/DexTrades.sol";
import {PoolIdLibrary, PoolId} from "./libs/UniswapV4/PoolId.sol";
import {Currency} from "./libs/UniswapV4/Currency.sol";
import {PoolKey} from "./libs/UniswapV4/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "./libs/UniswapV4/BalanceDelta.sol";
import {IHooks} from "./interfaces/UniswapV4/IHooks.sol";
import {NativeTokenResolver} from "./NativeTokenResolver.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract CLPoolManagerListener is CLPoolManager$OnSwapFunction, NativeTokenResolver, IDexListener {
    function CLPoolManager$onSwapFunction(
        FunctionContext memory ctx,
        CLPoolManager$SwapFunctionInputs memory inputs,
        CLPoolManager$SwapFunctionOutputs memory outputs
    ) external override {
        (string memory currency0Symbol, string memory currency0Name, uint256 currency0Decimals) = inputs.key.currency0
            == address(0)
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(inputs.key.currency0);
        (string memory currency1Symbol, string memory currency1Name, uint256 currency1Decimals) = inputs.key.currency1
            == address(0)
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(inputs.key.currency1);
        int128 amount1 = BalanceDeltaLibrary.amount1(BalanceDelta.wrap(outputs.delta));
        int128 amount0 = BalanceDeltaLibrary.amount0(BalanceDelta.wrap(outputs.delta));
        DexTradeData memory trade;
        trade.chainId = uint64(block.chainid);
        trade.transactionHash = ctx.txn.hash();
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = uint64(block.timestamp);
        trade.txnOriginator = tx.origin;
        trade.recipient = ctx.txn.call.caller();
        trade.liquidityPool = ctx.txn.call.callee();
        trade.dex = "PancakeSwapInfinity";

        if (inputs.params.zeroForOne) {
            trade.fromToken = inputs.key.currency0;
            trade.fromTokenAmt = amount0 < 0 ? uint128(-amount0) : uint128(amount0);
            trade.fromTokenSymbol = currency0Symbol;
            trade.fromTokenName = currency0Name;
            trade.fromTokenDecimals = uint8(currency0Decimals);
            trade.toToken = inputs.key.currency1;
            trade.toTokenAmt = amount1 < 0 ? uint128(-amount1) : uint128(amount1);
            trade.toTokenSymbol = currency1Symbol;
            trade.toTokenName = currency1Name;
            trade.toTokenDecimals = uint8(currency1Decimals);
        } else {
            trade.fromToken = inputs.key.currency1;
            trade.fromTokenAmt = amount1 < 0 ? uint128(-amount1) : uint128(amount1);
            trade.fromTokenSymbol = currency1Symbol;
            trade.fromTokenName = currency1Name;
            trade.fromTokenDecimals = uint8(currency1Decimals);
            trade.toToken = inputs.key.currency0;
            trade.toTokenAmt = amount0 < 0 ? uint128(-amount0) : uint128(amount0);
            trade.toTokenSymbol = currency0Symbol;
            trade.toTokenName = currency0Name;
            trade.toTokenDecimals = uint8(currency0Decimals);
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
