// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract GPv2SettlementListener is
    GPv2Settlement$PreSettleFunction,
    GPv2Settlement$OnSettleFunction,
    GPv2Settlement$OnTradeEvent,
    IDexListener
{
    bool internal inSettlement = false;

    function GPv2Settlement$preSettleFunction(PreFunctionContext memory, GPv2Settlement$SettleFunctionInputs memory)
        external
        override
    {
        inSettlement = true;
    }

    function GPv2Settlement$onSettleFunction(FunctionContext memory, GPv2Settlement$SettleFunctionInputs memory)
        external
        override
    {
        inSettlement = false;
    }

    function GPv2Settlement$onTradeEvent(EventContext memory ctx, GPv2Settlement$TradeEventParams memory params)
        external
        override
    {
        (string memory sellTokenName, string memory sellTokenSymbol, uint256 sellTokenDecimals) =
            getMetadata(params.sellToken);
        (string memory buyTokenName, string memory buyTokenSymbol, uint256 buyTokenDecimals) =
            getMetadata(params.buyToken);
        DexTradeData memory trade;
        trade.dex = "CoWProtocol";
        trade.fromToken = params.sellToken;
        trade.fromTokenAmt = params.sellAmount;
        trade.fromTokenName = sellTokenName;
        trade.fromTokenSymbol = sellTokenSymbol;
        trade.fromTokenDecimals = uint8(sellTokenDecimals);
        trade.toToken = params.buyToken;
        trade.toTokenAmt = params.buyAmount;
        trade.toTokenName = buyTokenName;
        trade.toTokenSymbol = buyTokenSymbol;
        trade.toTokenDecimals = uint8(buyTokenDecimals);
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = params.owner;
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
