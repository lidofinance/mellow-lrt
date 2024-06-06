// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

import  "../../../scripts/mainnet/DeployInterfaces.sol";
import "../../../src/interfaces/external/lido/IWeth.sol";
import "../../../src/interfaces/modules/symbiotic/IDefaultBondModule.sol";

interface stETH is ISteth, IERC20 {
    function DEPOSIT_SIZE() external view returns (uint256);
}

interface wstETH is IWSteth, IERC20 {
}

struct DeploymentConfiguration {
        Vault vault; // TransparantUpgradeableProxy
        IVaultConfigurator configurator;
        ManagedValidator validator;
        DefaultBondStrategy defaultBondStrategy;
        DepositWrapper depositWrapper;
        TimelockController timeLockedCurator;
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


contract MainnetTestBlueprint is Test{
    enum Deploy {
        STEAKHOUSE, RE7, MEVCAP
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
        deploymentConfigurations.push(DeploymentConfiguration(
                Vault(payable(0xa77a8D25cEB4B9F38A711850751edAc70d7b91b0)),
                IVaultConfigurator(0x7dB7dA79AF0Fe678634A51e1f57a091Fd485f7f8),
                ManagedValidator(0xd1928e2675a9be18f08d9aCe1A8008aaDEa3d813),
                DefaultBondStrategy(0x378F3AD5F48524bb2cD9A0f88B6AA525BaB2cB62),
                DepositWrapper(payable(0x9CaA80709b4F9a72b70efc7Db4bE0150Bf362126)),
                TimelockController(payable(0xF1504311dB8df3e02D56Ef6a2278188969cC2EDA)),
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
        deploymentConfigurations.push(DeploymentConfiguration(
                Vault(payable(0x20eF170856B8A746Df78406bfC2535b36F35774F)),
                IVaultConfigurator(0x3492407B9b8e0619d4fF423265F1cA5BE5198dd8),
                ManagedValidator(0xa064e9D2599b7029Bb5d4896812D339ac1aAa111),
                DefaultBondStrategy(0x6c4Aa164e733292586Fd09b92d86f3e5fa8E0772),
                DepositWrapper(payable(0x9d9d932Ff608F505EAd156E79C87A98Eb0527A1c)),
                TimelockController(payable(0xF84Bf03bcd79e09796E69134C2a6Ba6b60aC4eAB)),
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
        deploymentConfigurations.push(DeploymentConfiguration(
                Vault(payable(0xbF0311DF31aF8b027A12051c00d02aA85A322594)),
                IVaultConfigurator(0x63B844b3b0E6774403812652A0c4f65f9Dd8CdEc),
                ManagedValidator(0x819ed5ff31bAc8388C32182115517da660Cd7049),
                DefaultBondStrategy(0xEA872051b66C72136d07b8c53ed03539fCB6C3d6),
                DepositWrapper(payable(0x33757bE32998e524bbA895F2eA53D2e3Dc65cdf0)),
                TimelockController(payable(0x219e27E646db8a51348e6c87d2814d715664CE3c)),
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
    }
}


contract TestHelpers is MainnetTestBlueprint {
    uint256 public constant Q96 = 2 ** 96;

    function calculateLPAmount(uint256 depositAmount, DeploymentConfiguration memory config) public view returns (uint256 lpAmount) {
        (, uint256[] memory amounts) = config.vault.underlyingTvl();
        uint256 underluingTvl = amounts[0];
        lpAmount = depositAmount / underluingTvl * config.vault.totalSupply();
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
}
