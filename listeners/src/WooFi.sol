// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract WooFiListener is WooSwap$OnWooSwapEvent, DexUtils, IDexListener {
    function WooSwap$onWooSwapEvent(EventContext memory ctx, WooSwap$WooSwapEventParams memory params)
        external
        override
    {
        (string memory baseTokenName, string memory baseTokenSymbol, uint256 baseTokenDecimals) =
            getMetadata(params.fromToken);
        (string memory quoteTokenName, string memory quoteTokenSymbol, uint256 quoteTokenDecimals) =
            getMetadata(params.toToken);
        DexTradeData memory trade;
        trade.fromToken = params.fromToken;
        trade.fromTokenName = baseTokenName;
        trade.fromTokenSymbol = baseTokenSymbol;
        trade.fromTokenDecimals = uint8(baseTokenDecimals);
        trade.toToken = params.toToken;
        trade.toTokenName = quoteTokenName;
        trade.toTokenSymbol = quoteTokenSymbol;
        trade.toTokenDecimals = uint8(quoteTokenDecimals);
        trade.dex = "WooFi";
        trade.fromTokenAmt = params.fromAmount;
        trade.toTokenAmt = params.toAmount;
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
