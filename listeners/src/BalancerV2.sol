// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-generated/Generated.sol";
import "sim-idx-sol/Simidx.sol";
import "./types/DexTrades.sol";
import "./utils/ERC20Metadata.sol";
import "./DexUtils.sol";
import {IVault} from "./interfaces/Balancer/BalancerInterfaces.sol";
import "./interfaces/IDexListener.sol";
import {ChainlinkPriceFetcher} from "./utils/ChainlinkPriceFetcher.sol";

contract BalancerV2Listener is
    Vault$PreSwapFunction,
    Vault$PreBatchSwapFunction,
    Vault$OnSwapEvent,
    DexUtils,
    IDexListener
{
    address internal recipient;

    function Vault$preSwapFunction(PreFunctionContext memory, Vault$SwapFunctionInputs memory inputs)
        external
        override
    {
        recipient = inputs.funds.recipient;
    }

    function Vault$preBatchSwapFunction(PreFunctionContext memory, Vault$BatchSwapFunctionInputs memory inputs)
        external
        override
    {
        recipient = inputs.funds.recipient;
    }

    function Vault$onSwapEvent(EventContext memory ctx, Vault$SwapEventParams memory params) external override {
        (address pool,) = IVault(ctx.txn.call.callee()).getPool(params.poolId);
        (string memory tokenInName, string memory tokenInSymbol, uint256 tokenInDecimals) = getMetadata(params.tokenIn);
        (string memory tokenOutName, string memory tokenOutSymbol, uint256 tokenOutDecimals) =
            getMetadata(params.tokenOut);
        DexTradeData memory trade;
        if (ctx.txn.call.callee() == DexUtils.getBalancerV2Vault()) {
            trade.dex = "BalancerV2";
        } else if (ctx.txn.call.callee() == DexUtils.getSwaapV2Vault()) {
            trade.dex = "SwaapV2";
        } else {
            return;
        }
        trade.fromToken = params.tokenIn;
        trade.fromTokenAmt = params.amountIn;
        trade.fromTokenName = tokenInName;
        trade.fromTokenSymbol = tokenInSymbol;
        trade.fromTokenDecimals = uint8(tokenInDecimals);
        trade.toToken = params.tokenOut;
        trade.toTokenAmt = params.amountOut;
        trade.toTokenName = tokenOutName;
        trade.toTokenSymbol = tokenOutSymbol;
        trade.toTokenDecimals = uint8(tokenOutDecimals);
        trade.chainId = uint64(block.chainid);
        trade.blockNumber = blockNumber();
        trade.blockTimestamp = block.timestamp;
        trade.transactionHash = ctx.txn.hash();
        trade.txnOriginator = tx.origin;
        trade.recipient = recipient;
        trade.liquidityPool = pool;

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
