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

    uint256 internal constant CHAIN_ID_ETH = 1;
    uint256 internal constant CHAIN_ID_OPTIMISM = 10;
    uint256 internal constant CHAIN_ID_UNICHAIN = 130;
    uint256 internal constant CHAIN_ID_WORLDCHAIN = 480;
    uint256 internal constant CHAIN_ID_BASE = 8453;
    uint256 internal constant CHAIN_ID_MODE = 34443;
    uint256 internal constant CHAIN_ID_ARBITRUM = 42161;
    uint256 internal constant CHAIN_ID_INK = 57073;
    uint256 internal constant CHAIN_ID_BOB = 60808;
    uint256 internal constant CHAIN_ID_ZORA = 7777777;
    uint256 internal constant CHAIN_ID_SHAPE = 360;
    uint256 internal constant CHAIN_ID_SONEIUM = 1868;

    constructor() {

        // native ETH uses WETH/USD feed
        assetPriceFeeds[CHAIN_ID_ETH][0x0000000000000000000000000000000000000000] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        assetPriceFeeds[CHAIN_ID_OPTIMISM][0x0000000000000000000000000000000000000000] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        assetPriceFeeds[CHAIN_ID_BASE][0x0000000000000000000000000000000000000000] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        assetPriceFeeds[CHAIN_ID_ARBITRUM][0x0000000000000000000000000000000000000000] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        assetPriceFeeds[CHAIN_ID_BOB][0x0000000000000000000000000000000000000000] = 0x0268F2F1dAd17Bcc2b19b48b86c1B75D4afe8949;
        
        // (W)ETH/USD
        assetPriceFeeds[CHAIN_ID_ETH][0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        assetPriceFeeds[CHAIN_ID_OPTIMISM][0x4200000000000000000000000000000000000006] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        // no feeds for CHAIN_ID_UNICHAIN (130)
        // no feeds for CHAIN_ID_WORLDCHAIN (480)
        assetPriceFeeds[CHAIN_ID_BASE][0x4200000000000000000000000000000000000006] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        // no feeds for CHAIN_ID_MODE (34443)
        assetPriceFeeds[CHAIN_ID_ARBITRUM][0x82aF49447D8a07e3bd95BD0d56f35241523fBab1] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        // no feeds for CHAIN_ID_INK (57073)
        // no feeds for CHAIN_ID_ZORA (7777777)
        assetPriceFeeds[CHAIN_ID_BOB][0x4200000000000000000000000000000000000006] = 0x0268F2F1dAd17Bcc2b19b48b86c1B75D4afe8949;
        // no WETH on Soneium
        // no WETH on Shape


        // USDC/USD
        assetPriceFeeds[CHAIN_ID_ETH][0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        assetPriceFeeds[CHAIN_ID_OPTIMISM][0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85] = 0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3;
        // no feeds for CHAIN_ID_UNICHAIN (130)
        // no feeds for CHAIN_ID_WORLDCHAIN (480)
        assetPriceFeeds[CHAIN_ID_BASE][0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913] = 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B;
        // no feeds for CHAIN_ID_MODE (34443)
        assetPriceFeeds[CHAIN_ID_ARBITRUM][0xaf88d065e77c8cC2239327C5EDb3A432268e5831] = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
        // no feeds for CHAIN_ID_INK (57073)
        // no feeds for CHAIN_ID_ZORA (7777777)
        // no usdc on Bob
        // no WETH on Soneium
        // no WETH on Shape


        // USDT/USD
        assetPriceFeeds[CHAIN_ID_ETH][0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        assetPriceFeeds[CHAIN_ID_OPTIMISM][0x94b008aA00579c1307B0EF2c499aD98a8ce58e58] = 0xECef79E109e997bCA29c1c0897ec9d7b03647F5E;

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
