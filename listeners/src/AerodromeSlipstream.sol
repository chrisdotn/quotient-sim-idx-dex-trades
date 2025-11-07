// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import "./interfaces/Aerodrome/AerodromeSlipstream.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract AerodromeSlipstreamListener is CLPool$OnSwapFunction, DexUtils, IDexListener {
    function CLPool$onSwapFunction(
        FunctionContext memory ctx,
        CLPool$SwapFunctionInputs memory inputs,
        CLPool$SwapFunctionOutputs memory outputs
    ) external override {
        (address token0, address token1) = DexUtils.getAerodromeSlipstreamPoolMetadata(ctx.txn.call.callee());
        (string memory token0Name, string memory token0Symbol, uint256 token0Decimals) = getMetadata(token0);
        (string memory token1Name, string memory token1Symbol, uint256 token1Decimals) = getMetadata(token1);
        DexTradeData memory trade;
        address factory = ICLPoolConstants(ctx.txn.call.callee()).factory();
        if (factory == DexUtils.getAerodromeSlipstreamFactory()) {
            trade.dex = "AerodromeSlipstream";
        } else if (factory == DexUtils.getVelodromeSlipstreamFactory()) {
            trade.dex = "VelodromeSlipstream";
        } else {
            return;
        }
        if (inputs.zeroForOne) {
            trade.fromToken = token0;
            trade.fromTokenAmt = outputs.amount0 < 0 ? uint256(-outputs.amount0) : uint256(outputs.amount0);
            trade.fromTokenName = token0Name;
            trade.fromTokenSymbol = token0Symbol;
            trade.fromTokenDecimals = uint8(token0Decimals);
            trade.toToken = token1;
            trade.toTokenAmt = outputs.amount1 < 0 ? uint256(-outputs.amount1) : uint256(outputs.amount1);
            trade.toTokenName = token1Name;
            trade.toTokenSymbol = token1Symbol;
            trade.toTokenDecimals = uint8(token1Decimals);
        } else {
            trade.fromToken = token1;
            trade.fromTokenAmt = outputs.amount1 < 0 ? uint256(-outputs.amount1) : uint256(outputs.amount1);
            trade.fromTokenName = token1Name;
            trade.fromTokenSymbol = token1Symbol;
            trade.fromTokenDecimals = uint8(token1Decimals);
            trade.toToken = token0;
            trade.toTokenAmt = outputs.amount0 < 0 ? uint256(-outputs.amount0) : uint256(outputs.amount0);
            trade.toTokenName = token0Name;
            trade.toTokenSymbol = token0Symbol;
            trade.toTokenDecimals = uint8(token0Decimals);
        }
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = inputs.recipient;
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
