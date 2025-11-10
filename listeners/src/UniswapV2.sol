// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import "./interfaces/Uniswap/UniswapInterfaces.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract UniswapV2Listener is UniswapV2Pair$OnSwapEvent, DexUtils, IDexListener {
    function UniswapV2Pair$onSwapEvent(EventContext memory ctx, UniswapV2Pair$SwapEventParams memory params)
        external
        override
    {
        (address token0, address token1) = DexUtils.getUniswapV2PairMetadata(ctx.txn.call.callee());
        (string memory token0Name, string memory token0Symbol, uint256 token0Decimals) = getMetadata(token0);
        (string memory token1Name, string memory token1Symbol, uint256 token1Decimals) = getMetadata(token1);
        DexTradeData memory trade;
        address factory = IUniswapV2Pair(ctx.txn.call.callee()).factory();
        if (factory == DexUtils.getUniswapV2Factory()) {
            trade.dex = "UniswapV2";
        } else if (factory == DexUtils.getSushiSwapV2Factory()) {
            trade.dex = "SushiSwapV2";
        } else if (factory == DexUtils.getPancakeSwapV2Factory()) {
            trade.dex = "PancakeSwapV2";
        } else if (factory == DexUtils.getShibaSwapV2Factory()) {
            trade.dex = "ShibaSwapV2";
        } else if (factory == DexUtils.getRingSwapFactory()) {
            trade.dex = "RingSwap";
        } else if (factory == DexUtils.getCroDefiSwapFactory()) {
            trade.dex = "CroDefiSwap";
        } else if (factory == DexUtils.getDXSwapFactory()) {
            trade.dex = "DXSwap";
        } else if (factory == DexUtils.getSquadSwapFactory()) {
            trade.dex = "SquadSwap";
        } else if (factory == DexUtils.getTrebleSwapV2Factory()) {
            trade.dex = "TrebleSwapV2";
        } else if (factory == DexUtils.getBaseSwapFactory()) {
            trade.dex = "BaseSwap";
        } else if (factory == DexUtils.getSharkSwapFactory()) {
            trade.dex = "SharkSwap";
        } else if (factory == DexUtils.getRocketSwapFactory()) {
            trade.dex = "RocketSwap";
        } else if (factory == DexUtils.getAerodromeFactory()) {
            trade.dex = "Aerodrome";
        } else if (factory == DexUtils.getInfusionFactory()) {
            trade.dex = "Infusion";
        } else if (factory == DexUtils.getGammaSwapV2Factory()) {
            trade.dex = "GammaSwap";
        } else {
            return;
        }
        bool zfo = (params.amount0In > 0);
        if (zfo) {
            trade.fromToken = token0;
            trade.fromTokenAmt = params.amount0In;
            trade.fromTokenName = token0Name;
            trade.fromTokenSymbol = token0Symbol;
            trade.fromTokenDecimals = uint8(token0Decimals);
            trade.toToken = token1;
            trade.toTokenAmt = params.amount1Out;
            trade.toTokenName = token1Name;
            trade.toTokenSymbol = token1Symbol;
            trade.toTokenDecimals = uint8(token1Decimals);
        } else {
            trade.fromToken = token1;
            trade.fromTokenAmt = params.amount1In;
            trade.fromTokenName = token1Name;
            trade.fromTokenSymbol = token1Symbol;
            trade.fromTokenDecimals = uint8(token1Decimals);
            trade.toToken = token0;
            trade.toTokenAmt = params.amount0Out;
            trade.toTokenName = token0Name;
            trade.toTokenSymbol = token0Symbol;
            trade.toTokenDecimals = uint8(token0Decimals);
        }
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
