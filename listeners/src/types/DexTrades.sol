// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title DexTrade
/// @notice A struct that contains information about a DEX trade
/// @dev This struct is used to store information about a DEX trade
/// @param chainId The chain ID of the trade
/// @param blockNumber The block number of the trade
/// @param blockTimestamp The timestamp of the trade
/// @param transactionHash The hash of the transaction
/// @param dex The name of the DEX
/// @param fromToken The address of the token being sold
/// @param fromTokenAmt The amount of the token being sold
/// @param fromTokenName The name of the token being sold
/// @param fromTokenSymbol The symbol of the token being sold
/// @param fromTokenDecimals The number of decimals of the token being sold
/// @param toToken The address of the token being bought
/// @param toTokenAmt The amount of the token being bought
/// @param toTokenName The name of the token being bought
/// @param toTokenSymbol The symbol of the token being bought
/// @param toTokenDecimals The number of decimals of the token being bought
/// @param txnOriginator The address of the transaction originator
/// @param recipient The address of the recipient
/// @param liquidityPool The address of the liquidity pool
/// @param usdcValue The value of the trade in USDC
struct DexTradeData {
    uint64 chainId;
    uint256 blockNumber;
    uint256 blockTimestamp;
    bytes32 transactionHash;
    string dex;
    address fromToken;
    uint256 fromTokenAmt;
    string fromTokenName;
    string fromTokenSymbol;
    uint8 fromTokenDecimals;
    address toToken;
    uint256 toTokenAmt;
    string toTokenName;
    string toTokenSymbol;
    uint8 toTokenDecimals;
    address txnOriginator;
    address recipient;
    address liquidityPool;
    uint256 usdcValue;
}
