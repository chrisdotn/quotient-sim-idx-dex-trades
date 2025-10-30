// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 < 0.9.0;

import {safeReturnAddress} from "./AddressUtils.sol";
import {AggregatorV3Interface} from "../interfaces/Chainlink/ChainlinkInterfaces.sol";

/// @title A Chainlink on-chain price fetcher.
/// @author Tal Vaizman
/// @notice Fetches USD quotes of tokens from Chainlink feeds.
/// @notice Chain agnostic.
contract ChainlinkPriceFetcher {
    mapping(uint256 => mapping(address => address)) internal assetPriceFeeds;

    constructor() {
        // (W)ETH/USD
        assetPriceFeeds[1][0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 0x5147eA642CAEF7BD9c1265AadcA78f997AbB9649;
        assetPriceFeeds[10][0x4200000000000000000000000000000000000006] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        assetPriceFeeds[42161][0x82aF49447D8a07e3bd95BD0d56f35241523fBab1] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        assetPriceFeeds[8453][0x4200000000000000000000000000000000000006] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    }

    function getAssetPriceFeed(address baseAsset) internal view returns (address) {
        return safeReturnAddress(assetPriceFeeds[block.chainid][baseAsset]);
    }

    /// @notice Returns the components that can be used to calculate a given asset's price in USD.
    /// @param baseAsset The asset's address.
    /// @return The current quote of the asset in USD.
    /// @return USD decimals.
    function getChainlinkDataFeedLatestAnswer(address baseAsset) public view returns (uint256, uint256) {
        address dataFeed = getAssetPriceFeed(baseAsset);
        if (dataFeed == address(0)) {
            return (0, 0);
        }
        (
            /* uint80 roundID */
            ,
            int256 answer,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(dataFeed).latestRoundData();
        uint8 dec = AggregatorV3Interface(dataFeed).decimals();
        return (uint256(answer), dec);
    }
}
