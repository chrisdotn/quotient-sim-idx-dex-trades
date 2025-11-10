// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import "./interfaces/Maverick/MaverickV2.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract MaverickV2Listener is MaverickV2Pool$OnPoolSwapEvent, DexUtils, IDexListener {
    function MaverickV2Pool$onPoolSwapEvent(EventContext memory ctx, MaverickV2Pool$PoolSwapEventParams memory params)
        external
        override
    {
        address tokenA = IMaverickV2Pool(ctx.txn.call.callee()).tokenA();
        address tokenB = IMaverickV2Pool(ctx.txn.call.callee()).tokenB();
        if (!IMaverickV2Factory(DexUtils.getMaverickV2Factory()).isFactoryPool(ctx.txn.call.callee())) {
            return;
        }
        (string memory tokenAName, string memory tokenASymbol, uint256 tokenADecimals) = getMetadata(tokenA);
        (string memory tokenBName, string memory tokenBSymbol, uint256 tokenBDecimals) = getMetadata(tokenB);
        DexTradeData memory trade;

        if (params.params.tokenAIn) {
            trade.fromToken = tokenA;
            trade.fromTokenName = tokenAName;
            trade.fromTokenSymbol = tokenASymbol;
            trade.fromTokenDecimals = uint8(tokenADecimals);
            trade.toToken = tokenB;
            trade.toTokenName = tokenBName;
            trade.toTokenSymbol = tokenBSymbol;
            trade.toTokenDecimals = uint8(tokenBDecimals);
        } else {
            trade.fromToken = tokenB;
            trade.fromTokenName = tokenBName;
            trade.fromTokenSymbol = tokenBSymbol;
            trade.fromTokenDecimals = uint8(tokenBDecimals);
            trade.toToken = tokenA;
            trade.toTokenName = tokenAName;
            trade.toTokenSymbol = tokenASymbol;
            trade.toTokenDecimals = uint8(tokenADecimals);
        }
        trade.dex = "MaverickV2";
        trade.fromTokenAmt = params.amountIn;
        trade.toTokenAmt = params.amountOut;
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.recipient;
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
