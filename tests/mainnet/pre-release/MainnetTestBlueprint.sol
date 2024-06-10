// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

import "../../../scripts/mainnet/DeployInterfaces.sol";
import "../../../src/interfaces/external/lido/IWeth.sol";
import "../../../src/interfaces/modules/symbiotic/IDefaultBondModule.sol";

interface stETH is ISteth, IERC20 {
    function DEPOSIT_SIZE() external view returns (uint256);
}

interface wstETH is IWSteth, IERC20 {}

struct DeploymentConfiguration {
    Vault vault; // TransparantUpgradeableProxy
    IVaultConfigurator configurator;
    ManagedValidator validator;
    DefaultBondStrategy defaultBondStrategy;
    DepositWrapper depositWrapper;
    uint256 wstethAmountDeposited;
    address deployer;
    address proxyAdmin;
    address admin;
    address curator;
    address wstethDefaultBondFactory;
    address wstethDefaultBond;
    uint256 maximalTotalSupply;
    string lpTokenName;
    string lpTokenSymbol;
    uint256 initialDepositETH;
    uint256 timeLockDelay;
    Vault initialImplementation;
    Initializer initializer;
    ERC20TvlModule erc20TvlModule;
    DefaultBondTvlModule defaultBondTvlModule;
    DefaultBondModule defaultBondModule;
    ManagedRatiosOracle ratiosOracle;
    ChainlinkOracle priceOracle;
    IAggregatorV3 wethAggregatorV3;
    IAggregatorV3 wstethAggregatorV3;
    DefaultProxyImplementation defaultProxyImplementation;
    address ozProxyProxyAdmin;
}

contract MainnetTestBlueprint is Test {
    enum Deploy {
        STEAKHOUSE,
        RE7,
        MEVCAP
    }

    DeploymentConfiguration[] deploymentConfigurations;

    stETH immutable _STETH;
    wstETH immutable _WSTETH;
    IWeth immutable _WETH;

    constructor() {
        _STETH = stETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        _WSTETH = wstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        _WETH = IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        // Steakhouse Vault (test)
        deploymentConfigurations.push(
            DeploymentConfiguration(
                Vault(payable(0xa77a8D25cEB4B9F38A711850751edAc70d7b91b0)),
                IVaultConfigurator(0x7dB7dA79AF0Fe678634A51e1f57a091Fd485f7f8),
                ManagedValidator(0xd1928e2675a9be18f08d9aCe1A8008aaDEa3d813),
                DefaultBondStrategy(0x378F3AD5F48524bb2cD9A0f88B6AA525BaB2cB62),
                DepositWrapper(payable(0x9CaA80709b4F9a72b70efc7Db4bE0150Bf362126)),
                8557152514,
                0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf,
                0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be,
                0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6,
                0x2E93913A796a6C6b2bB76F41690E78a2E206Be54,
                0x3F95a719260ce6ec9622bC549c9adCff9edf16D9,
                0xB56dA788Aa93Ed50F50e0d38641519FfB3C3D1Eb,
                10000000000000000000000,
                "Steakhouse Vault (test)",
                "steakLRT (test)",
                10000000000,
                60,
                Vault(payable(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F)),
                Initializer(0x8f06BEB555D57F0D20dB817FF138671451084e24),
                ERC20TvlModule(0xCA60f449867c9101Ec80F8C611eaB39afE7bD638),
                DefaultBondTvlModule(0x48f758bd51555765EBeD4FD01c85554bD0B3c03B),
                DefaultBondModule(0x204043f4bda61F719Ad232b4196E1bc4131a3096),
                ManagedRatiosOracle(0x1437DCcA4e1442f20285Fb7C11805E7a965681e2),
                ChainlinkOracle(0xA5046e9379B168AFA154504Cf16853B6a7728436),
                IAggregatorV3(0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09),
                IAggregatorV3(0x773ae8ca45D5701131CA84C58821a39DdAdC709c),
                DefaultProxyImplementation(0x538459eeA06A06018C70bf9794e1c7b298694828),
                0x638113B8941327E4B0213Eefcb1319EC664DFD16
            )
        );
        // Re7 Labs LRT (test)
        deploymentConfigurations.push(
            DeploymentConfiguration(
                Vault(payable(0x20eF170856B8A746Df78406bfC2535b36F35774F)),
                IVaultConfigurator(0x3492407B9b8e0619d4fF423265F1cA5BE5198dd8),
                ManagedValidator(0xa064e9D2599b7029Bb5d4896812D339ac1aAa111),
                DefaultBondStrategy(0x6c4Aa164e733292586Fd09b92d86f3e5fa8E0772),
                DepositWrapper(payable(0x9d9d932Ff608F505EAd156E79C87A98Eb0527A1c)),
                8557152514,
                0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf,
                0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be,
                0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6,
                0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433,
                0x3F95a719260ce6ec9622bC549c9adCff9edf16D9,
                0xB56dA788Aa93Ed50F50e0d38641519FfB3C3D1Eb,
                10000000000000000000000,
                "Re7 Labs LRT (test)",
                "Re7LRT (test)",
                10000000000,
                60,
                Vault(payable(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F)),
                Initializer(0x8f06BEB555D57F0D20dB817FF138671451084e24),
                ERC20TvlModule(0xCA60f449867c9101Ec80F8C611eaB39afE7bD638),
                DefaultBondTvlModule(0x48f758bd51555765EBeD4FD01c85554bD0B3c03B),
                DefaultBondModule(0x204043f4bda61F719Ad232b4196E1bc4131a3096),
                ManagedRatiosOracle(0x1437DCcA4e1442f20285Fb7C11805E7a965681e2),
                ChainlinkOracle(0xA5046e9379B168AFA154504Cf16853B6a7728436),
                IAggregatorV3(0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09),
                IAggregatorV3(0x773ae8ca45D5701131CA84C58821a39DdAdC709c),
                DefaultProxyImplementation(0x538459eeA06A06018C70bf9794e1c7b298694828),
                0x3C6b61a0CFEE415F1Ebc11b095090b9fb21FAcC6
            )
        );

        // MEVcap ETH (test)
        deploymentConfigurations.push(
            DeploymentConfiguration(
                Vault(payable(0xbF0311DF31aF8b027A12051c00d02aA85A322594)),
                IVaultConfigurator(0x63B844b3b0E6774403812652A0c4f65f9Dd8CdEc),
                ManagedValidator(0x819ed5ff31bAc8388C32182115517da660Cd7049),
                DefaultBondStrategy(0xEA872051b66C72136d07b8c53ed03539fCB6C3d6),
                DepositWrapper(payable(0x33757bE32998e524bbA895F2eA53D2e3Dc65cdf0)),
                8557152514,
                0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf,
                0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be,
                0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6,
                0xA1E38210B06A05882a7e7Bfe167Cd67F07FA234A,
                0x3F95a719260ce6ec9622bC549c9adCff9edf16D9,
                0xB56dA788Aa93Ed50F50e0d38641519FfB3C3D1Eb,
                10000000000000000000000,
                "MEVcap ETH (test)",
                "mevcETH (test)",
                10000000000,
                60,
                Vault(payable(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F)),
                Initializer(0x8f06BEB555D57F0D20dB817FF138671451084e24),
                ERC20TvlModule(0xCA60f449867c9101Ec80F8C611eaB39afE7bD638),
                DefaultBondTvlModule(0x48f758bd51555765EBeD4FD01c85554bD0B3c03B),
                DefaultBondModule(0x204043f4bda61F719Ad232b4196E1bc4131a3096),
                ManagedRatiosOracle(0x1437DCcA4e1442f20285Fb7C11805E7a965681e2),
                ChainlinkOracle(0xA5046e9379B168AFA154504Cf16853B6a7728436),
                IAggregatorV3(0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09),
                IAggregatorV3(0x773ae8ca45D5701131CA84C58821a39DdAdC709c),
                DefaultProxyImplementation(0x538459eeA06A06018C70bf9794e1c7b298694828),
                0xaD09f49E43237f02Ad8b037805243fFb635Da796
            )
        );

        // Steakhouse (mainnet)
        deploymentConfigurations.push(
            DeploymentConfiguration(
                Vault(payable(0xBEEF69Ac7870777598A04B2bd4771c71212E6aBc)),
                IVaultConfigurator(0xe6180599432767081beA7deB76057Ce5883e73Be),
                ManagedValidator(0xdB66693845a3f72e932631080Efb1A86536D0EA7),
                DefaultBondStrategy(0x7a14b34a9a8EA235C66528dc3bF3aeFC36DFc268),
                DepositWrapper(payable(0x24fee15BC11fF617c042283B58A3Bda6441Da145)),
                8554034897,
                0x188858AC61a74350116d1CB6958fBc509FD6afA1,
                0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0,
                0x9437B2a8cF3b69D782a61f9814baAbc172f72003,
                0x2afc096981c2CFe3501bE4054160048718F6C0C8,
                0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec,
                0xC329400492c6ff2438472D4651Ad17389fCb843a,
                10322500000000000000000,
                "Steakhouse Resteaking Vault",
                "steakLRT",
                10000000000,
                60,
                Vault(payable(0xaf108ae0AD8700ac41346aCb620e828c03BB8848)),
                Initializer(0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c),
                ERC20TvlModule(0x1EB0e946D7d757d7b085b779a146427e40ABBCf8),
                DefaultBondTvlModule(0x1E1d1eD64e4F5119F60BF38B322Da7ea5A395429),
                DefaultBondModule(0xD8619769fed318714d362BfF01CA98ac938Bdf9b),
                ManagedRatiosOracle(0x955Ff4Cc738cDC009d2903196d1c94C8Cfb4D55d),
                ChainlinkOracle(0x1Dc89c28e59d142688D65Bd7b22C4Fd40C2cC06d),
                IAggregatorV3(0x6A8d8033de46c68956CCeBA28Ba1766437FF840F),
                IAggregatorV3(0x94336dF517036f2Bf5c620a1BC75a73A37b7bb16),
                DefaultProxyImplementation(0x02BB349832c58E892a20178b9696e2b93A3a9b0f),
                0xed792a3fDEB9044C70c951260AaAe974Fb3dB38F
            )
        );

        // Re7 (mainnet)
        deploymentConfigurations.push(
            DeploymentConfiguration(
                Vault(payable(0x84631c0d0081FDe56DeB72F6DE77abBbF6A9f93a)),
                IVaultConfigurator(0x214d66d110060dA2848038CA0F7573486363cAe4),
                ManagedValidator(0x0483B89F632596B24426703E540e373083928a6A),
                DefaultBondStrategy(0xcE3A8820265AD186E8C1CeAED16ae97176D020bA),
                DepositWrapper(payable(0x70cD3464A41B6692413a1Ba563b9D53955D5DE0d)),
                8554034897,
                0x188858AC61a74350116d1CB6958fBc509FD6afA1,
                0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0,
                0x9437B2a8cF3b69D782a61f9814baAbc172f72003,
                0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433,
                0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec,
                0xC329400492c6ff2438472D4651Ad17389fCb843a,
                10322500000000000000000,
                "Re7 Labs LRT",
                "Re7LRT",
                10000000000,
                60,
                Vault(payable(0xaf108ae0AD8700ac41346aCb620e828c03BB8848)),
                Initializer(0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c),
                ERC20TvlModule(0x1EB0e946D7d757d7b085b779a146427e40ABBCf8),
                DefaultBondTvlModule(0x1E1d1eD64e4F5119F60BF38B322Da7ea5A395429),
                DefaultBondModule(0xD8619769fed318714d362BfF01CA98ac938Bdf9b),
                ManagedRatiosOracle(0x955Ff4Cc738cDC009d2903196d1c94C8Cfb4D55d),
                ChainlinkOracle(0x1Dc89c28e59d142688D65Bd7b22C4Fd40C2cC06d),
                IAggregatorV3(0x6A8d8033de46c68956CCeBA28Ba1766437FF840F),
                IAggregatorV3(0x94336dF517036f2Bf5c620a1BC75a73A37b7bb16),
                DefaultProxyImplementation(0x02BB349832c58E892a20178b9696e2b93A3a9b0f),
                0xF076CF343DCfD01BBA57dFEB5C74F7B015951fcF
            )
        );

        // Mev Capital (mainnet)
        deploymentConfigurations.push(
            DeploymentConfiguration(
                Vault(payable(0x5fD13359Ba15A84B76f7F87568309040176167cd)),
                IVaultConfigurator(0x2dEc4fDC225C1f71161Ea481E23D66fEaAAE2391),
                ManagedValidator(0xD2635fa0635126bAfdD430b9614c0280d37a76CA),
                DefaultBondStrategy(0xc3A149b5Ca3f4A5F17F5d865c14AA9DBb570F10A),
                DepositWrapper(payable(0xdC1741f9bD33DD791942CC9435A90B0983DE8665)),
                8554034897,
                0x188858AC61a74350116d1CB6958fBc509FD6afA1,
                0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0,
                0x9437B2a8cF3b69D782a61f9814baAbc172f72003,
                0xA1E38210B06A05882a7e7Bfe167Cd67F07FA234A,
                0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec,
                0xC329400492c6ff2438472D4651Ad17389fCb843a,
                10322500000000000000000,
                "Amphor Restaked ETH",
                "amphrETH",
                10000000000,
                60,
                Vault(payable(0xaf108ae0AD8700ac41346aCb620e828c03BB8848)),
                Initializer(0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c),
                ERC20TvlModule(0x1EB0e946D7d757d7b085b779a146427e40ABBCf8),
                DefaultBondTvlModule(0x1E1d1eD64e4F5119F60BF38B322Da7ea5A395429),
                DefaultBondModule(0xD8619769fed318714d362BfF01CA98ac938Bdf9b),
                ManagedRatiosOracle(0x955Ff4Cc738cDC009d2903196d1c94C8Cfb4D55d),
                ChainlinkOracle(0x1Dc89c28e59d142688D65Bd7b22C4Fd40C2cC06d),
                IAggregatorV3(0x6A8d8033de46c68956CCeBA28Ba1766437FF840F),
                IAggregatorV3(0x94336dF517036f2Bf5c620a1BC75a73A37b7bb16),
                DefaultProxyImplementation(0x02BB349832c58E892a20178b9696e2b93A3a9b0f),
                0xc24891B75ef55fedC377c5e6Ec59A850b12E23ac
            )
        );

        // P2P (mainnet)
        deploymentConfigurations.push(
            DeploymentConfiguration(
                Vault(payable(0x7a4EffD87C2f3C55CA251080b1343b605f327E3a)),
                IVaultConfigurator(0x84b240E99d4C473b5E3dF1256300E2871412dDfe),
                ManagedValidator(0x6AB116ac709c89D90Cc1F8cD0323617A9996bA7c),
                DefaultBondStrategy(0xA0ea6d4fe369104eD4cc18951B95C3a43573C0F6),
                DepositWrapper(payable(0x41A1FBEa7Ace3C3a6B66a73e96E5ED07CDB2A34d)),
                8554034897,
                0x188858AC61a74350116d1CB6958fBc509FD6afA1,
                0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0,
                0x9437B2a8cF3b69D782a61f9814baAbc172f72003,
                0x4a3c7F2470Aa00ebE6aE7cB1fAF95964b9de1eF4,
                0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec,
                0xC329400492c6ff2438472D4651Ad17389fCb843a,
                10322500000000000000000,
                "Restaking Vault ETH",
                "rstETH",
                10000000000,
                60,
                Vault(payable(0xaf108ae0AD8700ac41346aCb620e828c03BB8848)),
                Initializer(0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c),
                ERC20TvlModule(0x1EB0e946D7d757d7b085b779a146427e40ABBCf8),
                DefaultBondTvlModule(0x1E1d1eD64e4F5119F60BF38B322Da7ea5A395429),
                DefaultBondModule(0xD8619769fed318714d362BfF01CA98ac938Bdf9b),
                ManagedRatiosOracle(0x955Ff4Cc738cDC009d2903196d1c94C8Cfb4D55d),
                ChainlinkOracle(0x1Dc89c28e59d142688D65Bd7b22C4Fd40C2cC06d),
                IAggregatorV3(0x6A8d8033de46c68956CCeBA28Ba1766437FF840F),
                IAggregatorV3(0x94336dF517036f2Bf5c620a1BC75a73A37b7bb16),
                DefaultProxyImplementation(0x02BB349832c58E892a20178b9696e2b93A3a9b0f),
                0x17AC6A90eD880F9cE54bB63DAb071F2BD3FE3772
            )
        );
    }
}

contract TestHelpers is MainnetTestBlueprint {
    using VaultLib for Vault;

    uint256 public constant Q96 = 2 ** 96;

    function calculateLPAmount(uint256 depositAmount, DeploymentConfiguration memory config)
        public
        view
        returns (uint256 lpAmount)
    {
        (, uint256[] memory amounts) = config.vault.underlyingTvl();
        uint256 underluingTvl = amounts[0];
        lpAmount = depositAmount * config.vault.totalSupply() / underluingTvl;
    }

    function rebase(int256 deltaBP) public {
        bytes32 CL_BALANCE_POSITION = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483; // keccak256("lido.Lido.beaconBalance");

        uint256 totalSupply = _STETH.totalSupply();
        uint256 clBalance = uint256(vm.load(address(_STETH), CL_BALANCE_POSITION));

        int256 delta = (deltaBP * int256(totalSupply) / 10000);
        vm.store(address(_STETH), CL_BALANCE_POSITION, bytes32(uint256(int256(clBalance) + delta)));

        assertEq(
            uint256(int256(totalSupply) * deltaBP / 10000 + int256(totalSupply)), _STETH.totalSupply(), "total supply"
        );
    }

    function assignWstETH(address to, uint256 amountOfEth) public returns (uint256 wstETHAmount) {
        vm.deal(to, amountOfEth);
        vm.startPrank(to);
        _STETH.submit{value: amountOfEth}(address(0));
        _STETH.approve(address(_WSTETH), type(uint256).max);
        wstETHAmount = _WSTETH.wrap(amountOfEth);
        vm.stopPrank();
    }

    function sum(uint256[] memory array) public pure returns (uint256 res) {
        for (uint256 i = 0; i < array.length; ++i) {
            res += array[i];
        }
    }
}

library VaultLib {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    stETH constant _STETH = stETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    wstETH constant _WSTETH = wstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    function deposit(Vault vault, address from, uint256 wstETHAmount) public returns (uint256 lpAmount) {
        vm.startPrank(from);
        _WSTETH.approve(address(vault), type(uint256).max);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = wstETHAmount;

        (, lpAmount) = vault.deposit(from, amounts, 0, type(uint256).max);
        vm.stopPrank();
    }

    function withdrawal(Vault vault, address owner, uint256 lpAmount, uint256 minAmount) public {
        vm.startPrank(owner);
        uint256[] memory minAmounts = new uint256[](1);
        minAmounts[0] = minAmount;
        vault.registerWithdrawal(owner, lpAmount, minAmounts, type(uint256).max, type(uint256).max, true);
        vm.stopPrank();
    }
}
