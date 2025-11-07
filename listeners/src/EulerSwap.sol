// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./interfaces/EulerSwap/IEulerSwap.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract EulerSwapListener is EulerSwap$OnSwapEvent, IDexListener {
    function EulerSwap$onSwapEvent(EventContext memory ctx, EulerSwap$SwapEventParams memory params)
        external
        override
    {
        (address token0, address token1) = IEulerSwap(ctx.txn.call.callee()).getAssets();
        (string memory token0Name, string memory token0Symbol, uint256 token0Decimals) = getMetadata(token0);
        (string memory token1Name, string memory token1Symbol, uint256 token1Decimals) = getMetadata(token1);
        DexTradeData memory trade;

        trade.fromToken = params.amount0In > 0 ? token0 : token1;
        trade.fromTokenName = params.amount0In > 0 ? token0Name : token1Name;
        trade.fromTokenSymbol = params.amount0In > 0 ? token0Symbol : token1Symbol;
        trade.fromTokenDecimals = uint8(params.amount0In > 0 ? token0Decimals : token1Decimals);
        trade.toToken = params.amount0In > 0 ? token1 : token0;
        trade.toTokenName = params.amount0In > 0 ? token1Name : token0Name;
        trade.toTokenSymbol = params.amount0In > 0 ? token1Symbol : token0Symbol;
        trade.toTokenDecimals = uint8(params.amount0In > 0 ? token1Decimals : token0Decimals);
        trade.dex = "EulerSwap";
        trade.fromTokenAmt = params.amount0In > 0 ? params.amount0In : params.amount1In;
        trade.toTokenAmt = params.amount0In > 0 ? params.amount1Out : params.amount0Out;
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
