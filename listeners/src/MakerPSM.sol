// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./libs/Maker/MakerLib.sol";
import "./utils/ERC20Metadata.sol";
import "./interfaces/IDexListener.sol";

contract MakerPSMListener is PSM$OnBuyGemFunction, PSM$OnSellGemFunction, IDexListener {
    function PSM$onBuyGemFunction(FunctionContext memory ctx, PSM$BuyGemFunctionInputs memory inputs)
        external
        override
    {
        address fromToken = MakerUtils.getDai(ctx.txn.call.callee());
        address toToken = MakerUtils.getGem(ctx.txn.call.callee());
        uint256 daiAmt = MakerUtils.getDaiAmt(ctx.txn.call.callee(), inputs.gemAmt, false);
        (string memory fromTokenName, string memory fromTokenSymbol, uint256 fromTokenDecimals) = getMetadata(fromToken);
        (string memory toTokenName, string memory toTokenSymbol, uint256 toTokenDecimals) = getMetadata(toToken);
        DexTradeData memory trade = DexTradeData({
            chainId: uint64(block.chainid),
            blockNumber: blockNumber(),
            blockTimestamp: block.timestamp,
            transactionHash: ctx.txn.hash(),
            dex: "MakerPSM",
            fromToken: fromToken,
            fromTokenAmt: daiAmt,
            fromTokenName: fromTokenName,
            fromTokenSymbol: fromTokenSymbol,
            fromTokenDecimals: uint8(fromTokenDecimals),
            toToken: toToken,
            toTokenAmt: inputs.gemAmt,
            toTokenName: toTokenName,
            toTokenSymbol: toTokenSymbol,
            toTokenDecimals: uint8(toTokenDecimals),
            txnOriginator: tx.origin,
            recipient: inputs.usr,
            liquidityPool: ctx.txn.call.callee(),
            usdcValue: 0
        });
        emit DexTrade(trade);
    }

    function PSM$onSellGemFunction(FunctionContext memory ctx, PSM$SellGemFunctionInputs memory inputs)
        external
        override
    {
        address toToken = MakerUtils.getDai(ctx.txn.call.callee());
        address fromToken = MakerUtils.getGem(ctx.txn.call.callee());
        uint256 daiAmt = MakerUtils.getDaiAmt(ctx.txn.call.callee(), inputs.gemAmt, true);
        (string memory fromTokenName, string memory fromTokenSymbol, uint256 fromTokenDecimals) = getMetadata(fromToken);
        (string memory toTokenName, string memory toTokenSymbol, uint256 toTokenDecimals) = getMetadata(toToken);
        DexTradeData memory trade = DexTradeData({
            chainId: uint64(block.chainid),
            blockNumber: blockNumber(),
            blockTimestamp: block.timestamp,
            transactionHash: ctx.txn.hash(),
            dex: "MakerPSM",
            fromToken: fromToken,
            fromTokenAmt: inputs.gemAmt,
            fromTokenName: fromTokenName,
            fromTokenSymbol: fromTokenSymbol,
            fromTokenDecimals: uint8(fromTokenDecimals),
            toToken: toToken,
            toTokenAmt: daiAmt,
            toTokenName: toTokenName,
            toTokenSymbol: toTokenSymbol,
            toTokenDecimals: uint8(toTokenDecimals),
            txnOriginator: tx.origin,
            recipient: inputs.usr,
            liquidityPool: ctx.txn.call.callee(),
            usdcValue: 0
        });
        emit DexTrade(trade);
    }
}
