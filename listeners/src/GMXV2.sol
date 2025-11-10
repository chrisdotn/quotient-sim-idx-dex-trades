// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract GMXV2Listener is EventEmitter$OnEventLog1Event, IDexListener {
    modifier onlySwapInfo(string memory eventName) {
        if (keccak256(bytes(eventName)) != keccak256(bytes("SwapInfo"))) return;
        _;
    }

    function EventEmitter$onEventLog1Event(EventContext memory ctx, EventEmitter$EventLog1EventParams memory params)
        external
        override
        onlySwapInfo(params.eventName)
    {
        (address tokenIn, address tokenOut) =
            (params.eventData.addressItems.items[2].value, params.eventData.addressItems.items[3].value);
        (string memory tokenInName, string memory tokenInSymbol, uint256 tokenInDecimals) = getMetadata(tokenIn);
        (string memory tokenOutName, string memory tokenOutSymbol, uint256 tokenOutDecimals) = getMetadata(tokenOut);
        DexTradeData memory trade;

        trade.fromToken = tokenIn;
        trade.fromTokenName = tokenInName;
        trade.fromTokenSymbol = tokenInSymbol;
        trade.fromTokenDecimals = uint8(tokenInDecimals);
        trade.toToken = tokenOut;
        trade.toTokenName = tokenOutName;
        trade.toTokenSymbol = tokenOutSymbol;
        trade.toTokenDecimals = uint8(tokenOutDecimals);
        trade.dex = "GMXV2";
        trade.fromTokenAmt = params.eventData.uintItems.items[2].value;
        trade.toTokenAmt = params.eventData.uintItems.items[4].value;
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.eventData.addressItems.items[1].value;
        trade.liquidityPool = params.eventData.addressItems.items[0].value;

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
