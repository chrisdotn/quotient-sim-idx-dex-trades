// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract DODOV2Listener is DODOSwap$OnDodoSwapEvent, DexUtils, IDexListener {
    function DODOSwap$onDodoSwapEvent(EventContext memory ctx, DODOSwap$DodoSwapEventParams memory params)
        external
        override
    {
        (address baseToken, address quoteToken) = DexUtils.getDodoV2PoolMetadata(ctx.txn.call.callee());

        (string memory baseTokenName, string memory baseTokenSymbol, uint256 baseTokenDecimals) = getMetadata(baseToken);
        (string memory quoteTokenName, string memory quoteTokenSymbol, uint256 quoteTokenDecimals) =
            getMetadata(quoteToken);
        DexTradeData memory trade;

        if (params.fromToken == baseToken) {
            trade.fromToken = baseToken;
            trade.fromTokenName = baseTokenName;
            trade.fromTokenSymbol = baseTokenSymbol;
            trade.fromTokenDecimals = uint8(baseTokenDecimals);
            trade.toToken = quoteToken;
            trade.toTokenName = quoteTokenName;
            trade.toTokenSymbol = quoteTokenSymbol;
            trade.toTokenDecimals = uint8(quoteTokenDecimals);
        } else {
            trade.fromToken = quoteToken;
            trade.fromTokenName = quoteTokenName;
            trade.fromTokenSymbol = quoteTokenSymbol;
            trade.fromTokenDecimals = uint8(quoteTokenDecimals);
            trade.toToken = baseToken;
            trade.toTokenName = baseTokenName;
            trade.toTokenSymbol = baseTokenSymbol;
            trade.toTokenDecimals = uint8(baseTokenDecimals);
        }
        trade.dex = "DODOV2";
        trade.fromTokenAmt = params.fromAmount;
        trade.toTokenAmt = params.toAmount;
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.receiver;
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
