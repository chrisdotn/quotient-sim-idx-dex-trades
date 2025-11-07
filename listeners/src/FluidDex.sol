// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import {IFluidDexT1} from "./interfaces/FluidDex/FluidDex.sol";
import "./NativeTokenResolver.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract FluidDexListener is FluidDexT1$OnSwapEvent, NativeTokenResolver, IDexListener {
    function FluidDexT1$onSwapEvent(EventContext memory ctx, FluidDexT1$SwapEventParams memory params)
        external
        override
    {
        IFluidDexT1.ConstantViews memory constantsView = IFluidDexT1(ctx.txn.call.callee()).constantsView();

        (string memory token0Name, string memory token0Symbol, uint256 token0Decimals) = constantsView.token0
            == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(constantsView.token0);
        (string memory token1Name, string memory token1Symbol, uint256 token1Decimals) = constantsView.token1
            == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            ? (nativeToken[block.chainid].symbol, nativeToken[block.chainid].name, nativeToken[block.chainid].decimals)
            : getMetadata(constantsView.token1);
        DexTradeData memory trade;

        if (params.swap0to1) {
            trade.fromToken = constantsView.token0;
            trade.fromTokenName = token0Name;
            trade.fromTokenSymbol = token0Symbol;
            trade.fromTokenDecimals = uint8(token0Decimals);
            trade.toToken = constantsView.token1;
            trade.toTokenName = token1Name;
            trade.toTokenSymbol = token1Symbol;
            trade.toTokenDecimals = uint8(token1Decimals);
        } else {
            trade.fromToken = constantsView.token1;
            trade.fromTokenName = token1Name;
            trade.fromTokenSymbol = token1Symbol;
            trade.fromTokenDecimals = uint8(token1Decimals);
            trade.toToken = constantsView.token0;
            trade.toTokenName = token0Name;
            trade.toTokenSymbol = token0Symbol;
            trade.toTokenDecimals = uint8(token0Decimals);
        }
        trade.dex = "FluidDex";
        trade.fromTokenAmt = params.amountIn;
        trade.toTokenAmt = params.amountOut;
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.to;
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
