// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./0xUtils.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract ZeroExSettlerListener is MainnetSettler$OnExecuteFunction, ZeroExUtils, IDexListener {
    function MainnetSettler$onExecuteFunction(
        FunctionContext memory ctx,
        MainnetSettler$ExecuteFunctionInputs memory inputs,
        MainnetSettler$ExecuteFunctionOutputs memory
    ) external override {
        RFQOrder[] memory orders = this.decodeCalls(inputs.actions, ctx.txn.call.callee());
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].maker == address(0)) {
                continue;
            }
            (string memory fromTokenName, string memory fromTokenSymbol, uint256 fromTokenDecimals) =
                getMetadata(orders[i].makerAsset);
            (string memory toTokenName, string memory toTokenSymbol, uint256 toTokenDecimals) =
                getMetadata(orders[i].takerAsset);
            DexTradeData memory trade;
            trade.fromToken = orders[i].makerAsset;
            trade.fromTokenName = fromTokenName;
            trade.fromTokenSymbol = fromTokenSymbol;
            trade.fromTokenDecimals = uint8(fromTokenDecimals);
            trade.toToken = orders[i].takerAsset;
            trade.toTokenName = toTokenName;
            trade.toTokenSymbol = toTokenSymbol;
            trade.toTokenDecimals = uint8(toTokenDecimals);
            trade.dex = "0xSettler";
            trade.fromTokenAmt = orders[i].makerAmount;
            trade.toTokenAmt = orders[i].takerAmount;
            trade.chainId = uint64(block.chainid);
            trade.blockNumber = blockNumber();
            trade.blockTimestamp = block.timestamp;
            trade.transactionHash = ctx.txn.hash();
            trade.txnOriginator = tx.origin;
            trade.recipient = orders[i].maker;
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
}
