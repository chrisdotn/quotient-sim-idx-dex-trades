// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "sim-idx-sol/Simidx.sol";
import "sim-idx-generated/Generated.sol";
import "./MakerPSM.sol";
import "./UniswapV2.sol";
import "./UniswapV3.sol";
import "./BancorCarbon.sol";
import "./GPv2Settlement.sol";
import "./CrocSwap.sol";
import "./Curve.sol";
import "./BalancerV2.sol";
import "./MaverickV1.sol";
import "./UniswapX.sol";
import "./UniswapV4.sol";
import "./DODOV2.sol";
import "./WooFi.sol";
import "./AirSwapV4.sol";
import "./AirSwapV5.sol";
import "./FluidDex.sol";
import "./1InchLOPV4.sol";
import "./KyberSwapLOP.sol";
import "./MaverickV2.sol";
import "./Ekubo.sol";
import "./0xProtocol.sol";
import "./0xSettler.sol";
import "./BalancerV3.sol";
import "./EulerSwap.sol";
import "./AerodromeSlipstream.sol";
import "./Aerodrome.sol";
import "./PancakeSwapV3.sol";
import "./BinPoolManager.sol";
import "./CLPoolManager.sol";
import "./AlgebraIntegral.sol";
import "./Algebra.sol";
import "./GMXV2.sol";
import "./Renegade.sol";

contract Triggers is ProtocolTriggers {
    using ChainsEnumerableMapLib for ChainsEnumerableMapLib.ChainsToChainIdContractMap;
    using ChainsEnumerableMapLib for ChainsEnumerableMapLib.ChainsToChainIdAbiMap;

    MakerPSMListener psmListener;
    UniswapV2Listener uniswapV2Listener;
    UniswapV3Listener uniswapV3Listener;
    BancorCarbonListener carbonListener;
    GPv2SettlementListener gpv2SettlementListener;
    CrocSwapListener crocSwapListener;
    CurveListener curveListener;
    BalancerV2Listener balancerV2Listener;
    MaverickV1Listener maverickV1Listener;
    UniswapXListener uniswapXListener;
    UniswapV4Listener uniswapV4Listener;
    DODOV2Listener dodoV2Listener;
    WooFiListener wooFiListener;
    AirSwapV4Listener airSwapV4Listener;
    AirSwapV5Listener airSwapV5Listener;
    FluidDexListener fluidDexListener;
    OneInchLOPV4Listener oneInchLOPV4Listener;
    KyberSwapLOPListener kyberSwapLOPListener;
    MaverickV2Listener maverickV2Listener;
    EkuboListener ekuboListener;
    ZeroExProtocolListener zeroExProtocolListener;
    ZeroExSettlerListener zeroExSettlerListener;
    BalancerV3Listener balancerV3Listener;
    EulerSwapListener eulerSwapListener;
    AerodromeSlipstreamListener aerodromeSlipstreamListener;
    AerodromeListener aerodromeListener;
    PancakeSwapV3Listener pancakeSwapV3Listener;
    BinPoolManagerListener binPoolManagerListener;
    CLPoolManagerListener cLPoolManagerListener;
    AlgebraIntegralListener algebraIntegralListener;
    AlgebraListener algebraListener;
    GMXV2Listener gmxV2Listener;
    RenegadeListener renegadeListener;

    ProtocolConfigAbi internal psmConfig;
    ProtocolConfigAbi internal univ2Config;
    ProtocolConfigAbi internal univ3Config;
    ProtocolConfigAddress internal bancorCarbonConfig;
    ProtocolConfigAddress internal gpv2SettlementConfig;
    ProtocolConfigAbi internal crocSwapConfig;
    ProtocolConfigAbi internal curveOldExchangeConfig;
    ProtocolConfigAbi internal curveExchangeConfig;
    ProtocolConfigAbi internal balancerV2Config;
    ProtocolConfigAbi internal maverickV1Config;
    ProtocolConfigAbi internal uniswapXConfig;
    ProtocolConfigAddress internal uniswapV4Config;
    ProtocolConfigAbi internal dodoV2Config;
    ProtocolConfigAbi internal wooFiConfig;
    ProtocolConfigAddress internal airSwapV4Config;
    ProtocolConfigAddress internal airSwapV5Config;
    ProtocolConfigAbi internal fluidDexConfig;
    ProtocolConfigAddress internal oneInchLOPV4Config;
    ProtocolConfigAddress internal kyberSwapLOPConfig;
    ProtocolConfigAddress internal kyberSwapDSLOPConfig;
    ProtocolConfigAbi internal maverickV2Config;
    ProtocolConfigAddress internal ekuboConfig;
    ProtocolConfigAddress internal zeroExProtocolConfig;
    ProtocolConfigAbi internal zeroExSettlerConfig;
    ProtocolConfigAddress internal balancerV3Config;
    ProtocolConfigAbi internal eulerSwapConfig;
    ProtocolConfigAbi internal aerodromeSlipstreamConfig;
    ProtocolConfigAbi internal aerodromeConfig;
    ProtocolConfigAbi internal pancakeSwapV3Config;
    ProtocolConfigAddress internal binPoolManagerConfig;
    ProtocolConfigAddress internal cLPoolManagerConfig;
    ProtocolConfigAbi internal algebraIntegralConfig;
    ProtocolConfigAbi internal algebraConfig;
    ProtocolConfigAddress internal gmxV2Config;
    ProtocolConfigAddress internal renegadeConfig;

    constructor() {
        // init listeners
        psmListener = new MakerPSMListener();
        uniswapV2Listener = new UniswapV2Listener();
        uniswapV3Listener = new UniswapV3Listener();
        carbonListener = new BancorCarbonListener();
        gpv2SettlementListener = new GPv2SettlementListener();
        crocSwapListener = new CrocSwapListener();
        curveListener = new CurveListener();
        balancerV2Listener = new BalancerV2Listener();
        maverickV1Listener = new MaverickV1Listener();
        uniswapXListener = new UniswapXListener();
        uniswapV4Listener = new UniswapV4Listener();
        dodoV2Listener = new DODOV2Listener();
        wooFiListener = new WooFiListener();
        airSwapV4Listener = new AirSwapV4Listener();
        airSwapV5Listener = new AirSwapV5Listener();
        fluidDexListener = new FluidDexListener();
        oneInchLOPV4Listener = new OneInchLOPV4Listener();
        kyberSwapLOPListener = new KyberSwapLOPListener();
        maverickV2Listener = new MaverickV2Listener();
        ekuboListener = new EkuboListener();
        zeroExProtocolListener = new ZeroExProtocolListener();
        zeroExSettlerListener = new ZeroExSettlerListener();
        balancerV3Listener = new BalancerV3Listener();
        eulerSwapListener = new EulerSwapListener();
        aerodromeSlipstreamListener = new AerodromeSlipstreamListener();
        aerodromeListener = new AerodromeListener();
        pancakeSwapV3Listener = new PancakeSwapV3Listener();
        binPoolManagerListener = new BinPoolManagerListener();
        cLPoolManagerListener = new CLPoolManagerListener();
        algebraIntegralListener = new AlgebraIntegralListener();
        algebraListener = new AlgebraListener();
        gmxV2Listener = new GMXV2Listener();
        renegadeListener = new RenegadeListener();

        // address resolving
        bancorCarbonConfig.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0xC537e898CD774e2dCBa3B14Ea6f34C93d5eA45e1)
        );
        bancorCarbonConfig.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0xA4682A2A5Fe02feFF8Bd200240A41AD0E6EaF8d5)
        );
        gpv2SettlementConfig.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0x9008D19f58AAbD9eD0D60971565AA8510560ab41)
        );
        gpv2SettlementConfig.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0x9008D19f58AAbD9eD0D60971565AA8510560ab41)
        );
        gpv2SettlementConfig.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0x9008D19f58AAbD9eD0D60971565AA8510560ab41)
        );
        uniswapV4Config.chainIdToAddressEnumerable.set(
            Chains.Unichain, chainContract(Chains.Unichain, 0x1F98400000000000000000000000000000000004)
        );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.Optimism, chainContract(Chains.Optimism, 0x9a13F98Cb987694C9F086b1F5eB990EeA8264Ec3)
        // );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.Zora, chainContract(Chains.Zora, 0x0575338e4C17006aE181B47900A84404247CA30f)
        // );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.WorldChain, chainContract(Chains.WorldChain, 0xb1860D529182ac3BC1F51Fa2ABd56662b7D13f33)
        // );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.Ink, chainContract(Chains.Ink, 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32)
        // );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.Soneium, chainContract(Chains.Soneium, 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32)
        // );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.Base, chainContract(Chains.Base, 0x498581fF718922c3f8e6A244956aF099B2652b2b)
        // );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.Ethereum, chainContract(Chains.Ethereum, 0x000000000004444c5dc75cB358380D2e3dE08A90)
        // );
        // uniswapV4Config.chainIdToAddressEnumerable.set(
        //     Chains.Arbitrum, chainContract(Chains.Arbitrum, 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32)
        // );
        airSwapV4Config.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0xd82FA167727a4dc6D6F55830A2c47aBbB4b3a0F8)
        );
        airSwapV5Config.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0xD82E10B9A4107939e55fCCa9B53A9ede6CF2fC46)
        );
        airSwapV5Config.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0xD82E10B9A4107939e55fCCa9B53A9ede6CF2fC46)
        );
        kyberSwapLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0x227B0c196eA8db17A665EA6824D972A64202E936)
        );
        kyberSwapDSLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0xcab2FA2eeab7065B45CBcF6E3936dDE2506b4f6C)
        );
        kyberSwapLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0x227B0c196eA8db17A665EA6824D972A64202E936)
        );
        kyberSwapDSLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0xcab2FA2eeab7065B45CBcF6E3936dDE2506b4f6C)
        );
        kyberSwapLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0x227B0c196eA8db17A665EA6824D972A64202E936)
        );
        kyberSwapDSLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0xcab2FA2eeab7065B45CBcF6E3936dDE2506b4f6C)
        );
        kyberSwapLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Optimism, chainContract(Chains.Optimism, 0x227B0c196eA8db17A665EA6824D972A64202E936)
        );
        kyberSwapDSLOPConfig.chainIdToAddressEnumerable.set(
            Chains.Optimism, chainContract(Chains.Optimism, 0xcab2FA2eeab7065B45CBcF6E3936dDE2506b4f6C)
        );
        ekuboConfig.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0xe0e0e08A6A4b9Dc7bD67BCB7aadE5cF48157d444)
        );
        zeroExProtocolConfig.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0xDef1C0ded9bec7F1a1670819833240f027b25EfF)
        );
        zeroExProtocolConfig.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0xDef1C0ded9bec7F1a1670819833240f027b25EfF)
        );
        zeroExProtocolConfig.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0xDef1C0ded9bec7F1a1670819833240f027b25EfF)
        );
        zeroExProtocolConfig.chainIdToAddressEnumerable.set(
            Chains.Optimism, chainContract(Chains.Optimism, 0xDEF1ABE32c034e558Cdd535791643C58a13aCC10)
        );
        oneInchLOPV4Config.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0x111111125421cA6dc452d289314280a0f8842A65)
        );
        oneInchLOPV4Config.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0x111111125421cA6dc452d289314280a0f8842A65)
        );
        oneInchLOPV4Config.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0x111111125421cA6dc452d289314280a0f8842A65)
        );
        oneInchLOPV4Config.chainIdToAddressEnumerable.set(
            Chains.Optimism, chainContract(Chains.Optimism, 0x111111125421cA6dc452d289314280a0f8842A65)
        );
        balancerV3Config.chainIdToAddressEnumerable.set(
            Chains.Ethereum, chainContract(Chains.Ethereum, 0xbA1333333333a1BA1108E8412f11850A5C319bA9)
        );
        balancerV3Config.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0xbA1333333333a1BA1108E8412f11850A5C319bA9)
        );
        balancerV3Config.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0xbA1333333333a1BA1108E8412f11850A5C319bA9)
        );
        balancerV3Config.chainIdToAddressEnumerable.set(
            Chains.Optimism, chainContract(Chains.Optimism, 0xbA1333333333a1BA1108E8412f11850A5C319bA9)
        );
        binPoolManagerConfig.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0xC697d2898e0D09264376196696c51D7aBbbAA4a9)
        );
        cLPoolManagerConfig.chainIdToAddressEnumerable.set(
            Chains.Base, chainContract(Chains.Base, 0xa0FfB9c1CE1Fe56963B0321B32E7A0302114058b)
        );
        gmxV2Config.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0xC8ee91A54287DB53897056e12D9819156D3822Fb)
        );
        renegadeConfig.chainIdToAddressEnumerable.set(
            Chains.Arbitrum, chainContract(Chains.Arbitrum, 0x30bD8eAb29181F790D7e495786d4B96d7AfDC518)
        );

        // protocol to abi
        psmConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, PSM$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Ink, chainAbi(Chains.Ink, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.WorldChain, chainAbi(Chains.WorldChain, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Soneium, chainAbi(Chains.Soneium, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Unichain, chainAbi(Chains.Unichain, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Zora, chainAbi(Chains.Zora, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, UniswapV2Pair$Abi()));
        univ2Config.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, UniswapV2Pair$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Ink, chainAbi(Chains.Ink, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Unichain, chainAbi(Chains.Unichain, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Zora, chainAbi(Chains.Zora, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.WorldChain, chainAbi(Chains.WorldChain, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Soneium, chainAbi(Chains.Soneium, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, UniswapV3Pool$Abi()));
        univ3Config.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, UniswapV3Pool$Abi()));
        crocSwapConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, HotProxy$Abi()));
        crocSwapConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, HotProxy$Abi()));
        curveOldExchangeConfig.chainIdToAbiEnumerable.set(
            Chains.Ethereum, chainAbi(Chains.Ethereum, OldTokenExchange$Abi())
        );
        curveExchangeConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, TokenExchange$Abi()));
        curveOldExchangeConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, OldTokenExchange$Abi()));
        curveExchangeConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, TokenExchange$Abi()));
        curveOldExchangeConfig.chainIdToAbiEnumerable.set(Chains.Ink, chainAbi(Chains.Ink, OldTokenExchange$Abi()));
        curveExchangeConfig.chainIdToAbiEnumerable.set(Chains.Ink, chainAbi(Chains.Ink, TokenExchange$Abi()));
        curveOldExchangeConfig.chainIdToAbiEnumerable.set(
            Chains.Arbitrum, chainAbi(Chains.Arbitrum, OldTokenExchange$Abi())
        );
        curveExchangeConfig.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, TokenExchange$Abi()));
        curveOldExchangeConfig.chainIdToAbiEnumerable.set(
            Chains.Optimism, chainAbi(Chains.Optimism, OldTokenExchange$Abi())
        );
        curveExchangeConfig.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, TokenExchange$Abi()));
        balancerV2Config.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, Vault$Abi()));
        balancerV2Config.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, Vault$Abi()));
        balancerV2Config.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, Vault$Abi()));
        balancerV2Config.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, Vault$Abi()));
        maverickV1Config.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, MaverickPool$Abi()));
        maverickV1Config.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, MaverickPool$Abi()));
        uniswapXConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, Reactor$Abi()));
        uniswapXConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, Reactor$Abi()));
        uniswapXConfig.chainIdToAbiEnumerable.set(Chains.Unichain, chainAbi(Chains.Unichain, Reactor$Abi()));
        uniswapXConfig.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, Reactor$Abi()));
        dodoV2Config.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, DODOSwap$Abi()));
        dodoV2Config.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, DODOSwap$Abi()));
        dodoV2Config.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, DODOSwap$Abi()));
        dodoV2Config.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, DODOSwap$Abi()));
        wooFiConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, WooSwap$Abi()));
        wooFiConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, WooSwap$Abi()));
        wooFiConfig.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, WooSwap$Abi()));
        wooFiConfig.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, WooSwap$Abi()));
        fluidDexConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, FluidDexT1$Abi()));
        fluidDexConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, FluidDexT1$Abi()));
        fluidDexConfig.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, FluidDexT1$Abi()));
        maverickV2Config.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, MaverickV2Pool$Abi()));
        maverickV2Config.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, MaverickV2Pool$Abi()));
        maverickV2Config.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, MaverickV2Pool$Abi()));
        zeroExSettlerConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, MainnetSettler$Abi()));
        zeroExSettlerConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, MainnetSettler$Abi()));
        zeroExSettlerConfig.chainIdToAbiEnumerable.set(Chains.Ink, chainAbi(Chains.Ink, MainnetSettler$Abi()));
        zeroExSettlerConfig.chainIdToAbiEnumerable.set(Chains.Unichain, chainAbi(Chains.Unichain, MainnetSettler$Abi()));
        zeroExSettlerConfig.chainIdToAbiEnumerable.set(
            Chains.WorldChain, chainAbi(Chains.WorldChain, MainnetSettler$Abi())
        );
        zeroExSettlerConfig.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, MainnetSettler$Abi()));
        zeroExSettlerConfig.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, MainnetSettler$Abi()));
        eulerSwapConfig.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, EulerSwap$Abi()));
        eulerSwapConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, EulerSwap$Abi()));
        eulerSwapConfig.chainIdToAbiEnumerable.set(Chains.Unichain, chainAbi(Chains.Unichain, EulerSwap$Abi()));
        eulerSwapConfig.chainIdToAbiEnumerable.set(Chains.BOB, chainAbi(Chains.BOB, EulerSwap$Abi()));
        eulerSwapConfig.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, EulerSwap$Abi()));
        aerodromeSlipstreamConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, CLPool$Abi()));
        aerodromeConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, AerodromePool$Abi()));
        aerodromeSlipstreamConfig.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, CLPool$Abi()));
        aerodromeConfig.chainIdToAbiEnumerable.set(Chains.Optimism, chainAbi(Chains.Optimism, AerodromePool$Abi()));
        pancakeSwapV3Config.chainIdToAbiEnumerable.set(Chains.Ethereum, chainAbi(Chains.Ethereum, PancakeV3Pool$Abi()));
        pancakeSwapV3Config.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, PancakeV3Pool$Abi()));
        pancakeSwapV3Config.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, PancakeV3Pool$Abi()));
        algebraIntegralConfig.chainIdToAbiEnumerable.set(Chains.Base, chainAbi(Chains.Base, AlgebraIntegralPool$Abi()));
        algebraConfig.chainIdToAbiEnumerable.set(Chains.Arbitrum, chainAbi(Chains.Arbitrum, AlgebraPool$Abi()));

        // per protocol triggers
        psmConfig.triggers = [psmListener.PSM$triggerOnBuyGemFunction(), psmListener.PSM$triggerOnSellGemFunction()];
        univ2Config.triggers = [uniswapV2Listener.UniswapV2Pair$triggerOnSwapEvent()];
        univ3Config.triggers = [uniswapV3Listener.UniswapV3Pool$triggerOnSwapFunction()];
        bancorCarbonConfig.triggers = [carbonListener.BancorController$triggerOnTokensTradedEvent()];
        gpv2SettlementConfig.triggers = [
            gpv2SettlementListener.GPv2Settlement$triggerPreSettleFunction(),
            gpv2SettlementListener.GPv2Settlement$triggerOnSettleFunction(),
            gpv2SettlementListener.GPv2Settlement$triggerOnTradeEvent()
        ];
        crocSwapConfig.triggers = [crocSwapListener.HotProxy$triggerOnUserCmdFunction()];
        curveOldExchangeConfig.triggers = [curveListener.OldTokenExchange$triggerOnTokenExchangeEvent()];
        curveExchangeConfig.triggers = [curveListener.TokenExchange$triggerOnTokenExchangeEvent()];
        balancerV2Config.triggers = [
            balancerV2Listener.Vault$triggerPreSwapFunction(),
            balancerV2Listener.Vault$triggerPreBatchSwapFunction(),
            balancerV2Listener.Vault$triggerOnSwapEvent()
        ];
        maverickV1Config.triggers = [maverickV1Listener.MaverickPool$triggerOnSwapEvent()];
        uniswapXConfig.triggers = [
            uniswapXListener.Reactor$triggerPreExecuteFunction(),
            uniswapXListener.Reactor$triggerPreExecuteBatchFunction(),
            uniswapXListener.Reactor$triggerPreExecuteBatchWithCallbackFunction(),
            uniswapXListener.Reactor$triggerPreExecuteWithCallbackFunction()
        ];
        uniswapV4Config.triggers = [uniswapV4Listener.PoolManager$triggerOnSwapFunction()];
        dodoV2Config.triggers = [dodoV2Listener.DODOSwap$triggerOnDodoSwapEvent()];
        wooFiConfig.triggers = [wooFiListener.WooSwap$triggerOnWooSwapEvent()];
        airSwapV4Config.triggers = [airSwapV4Listener.AirSwapV4$triggerOnSwapErc20Event()];
        airSwapV5Config.triggers = [
            airSwapV5Listener.AirSwapV5$triggerOnSwapFunction(),
            airSwapV5Listener.AirSwapV5$triggerOnSwapAnySenderFunction(),
            airSwapV5Listener.AirSwapV5$triggerOnSwapLightFunction()
        ];
        fluidDexConfig.triggers = [fluidDexListener.FluidDexT1$triggerOnSwapEvent()];
        oneInchLOPV4Config.triggers = [
            oneInchLOPV4Listener.AggregationRouterV6$triggerOnFillOrderFunction(),
            oneInchLOPV4Listener.AggregationRouterV6$triggerOnFillOrderArgsFunction(),
            oneInchLOPV4Listener.AggregationRouterV6$triggerOnFillContractOrderFunction(),
            oneInchLOPV4Listener.AggregationRouterV6$triggerOnFillContractOrderArgsFunction()
        ];
        kyberSwapLOPConfig.triggers = [
            kyberSwapLOPListener.LimitOrderProtocol$triggerOnFillOrderRfqToFunction(),
            kyberSwapLOPListener.LimitOrderProtocol$triggerOnFillOrderFunction(),
            kyberSwapLOPListener.LimitOrderProtocol$triggerOnFillBatchOrdersToFunction(),
            kyberSwapLOPListener.LimitOrderProtocol$triggerOnFillOrderToWithPermitFunction()
        ];
        kyberSwapDSLOPConfig.triggers = [kyberSwapLOPListener.DSLOProtocol$triggerOnFillOrderToFunction()];
        maverickV2Config.triggers = [maverickV2Listener.MaverickV2Pool$triggerOnPoolSwapEvent()];
        ekuboConfig.triggers = [
            ekuboListener.EkuboCore$triggerOnSwap611415377Function(),
            ekuboListener.EkuboCore$triggerPreLockFunction(),
            ekuboListener.EkuboCore$triggerOnLockFunction()
        ];
        zeroExProtocolConfig.triggers = [
            zeroExProtocolListener.ExchangeV4$triggerOnOtcOrderFilledEvent(),
            zeroExProtocolListener.ExchangeV4$triggerOnRfqOrderFilledEvent(),
            zeroExProtocolListener.ExchangeV4$triggerOnLimitOrderFilledEvent()
        ];
        balancerV3Config.triggers = [balancerV3Listener.BalancerV3Vault$triggerOnSwapFunction()];
        eulerSwapConfig.triggers = [eulerSwapListener.EulerSwap$triggerOnSwapEvent()];
        aerodromeSlipstreamConfig.triggers = [aerodromeSlipstreamListener.CLPool$triggerOnSwapFunction()];
        aerodromeConfig.triggers = [aerodromeListener.AerodromePool$triggerOnSwapEvent()];
        pancakeSwapV3Config.triggers = [pancakeSwapV3Listener.PancakeV3Pool$triggerOnSwapFunction()];
        binPoolManagerConfig.triggers = [binPoolManagerListener.BinPoolManager$triggerOnSwapFunction()];
        cLPoolManagerConfig.triggers = [cLPoolManagerListener.CLPoolManager$triggerOnSwapFunction()];
        algebraIntegralConfig.triggers = [algebraIntegralListener.AlgebraIntegralPool$triggerOnSwapEvent()];
        algebraConfig.triggers = [algebraListener.AlgebraPool$triggerOnSwapFunction()];
        gmxV2Config.triggers = [gmxV2Listener.EventEmitter$triggerOnEventLog1Event()];
        renegadeConfig.triggers = [renegadeListener.DarkPool$triggerOnProcessAtomicMatchSettleWithReceiverFunction()];
    }

    function triggers() external virtual override {
        // addTriggerForProtocol(psmConfig);
        // addTriggerForProtocol(univ2Config);
        // addTriggerForProtocol(univ3Config);
        // addTriggerForProtocol(bancorCarbonConfig);
        // addTriggerForProtocol(gpv2SettlementConfig);
        // addTriggerForProtocol(crocSwapConfig);
        // addTriggerForProtocol(curveOldExchangeConfig);
        // addTriggerForProtocol(curveExchangeConfig);
        // addTriggerForProtocol(balancerV2Config);
        // addTriggerForProtocol(maverickV1Config);
        // addTriggerForProtocol(uniswapXConfig);
        addTriggerForProtocol(uniswapV4Config);
        // addTriggerForProtocol(dodoV2Config);
        // addTriggerForProtocol(wooFiConfig);
        // addTriggerForProtocol(airSwapV4Config);
        // addTriggerForProtocol(airSwapV5Config);
        // addTriggerForProtocol(fluidDexConfig);
        // addTriggerForProtocol(oneInchLOPV4Config);
        // addTriggerForProtocol(kyberSwapLOPConfig);
        // addTriggerForProtocol(kyberSwapDSLOPConfig);
        // addTriggerForProtocol(maverickV2Config);
        // addTriggerForProtocol(ekuboConfig);
        // addTriggerForProtocol(zeroExProtocolConfig);
        // addTriggerForProtocol(zeroExSettlerConfig);
        // addTriggerForProtocol(balancerV3Config);
        // addTriggerForProtocol(eulerSwapConfig);
        // addTriggerForProtocol(aerodromeSlipstreamConfig);
        // addTriggerForProtocol(aerodromeConfig);
        // addTriggerForProtocol(pancakeSwapV3Config);
        // addTriggerForProtocol(binPoolManagerConfig);
        // addTriggerForProtocol(cLPoolManagerConfig);
        // addTriggerForProtocol(algebraIntegralConfig);
        // addTriggerForProtocol(algebraConfig);
        // addTriggerForProtocol(gmxV2Config);
        // addTriggerForProtocol(renegadeConfig);
    }
}
