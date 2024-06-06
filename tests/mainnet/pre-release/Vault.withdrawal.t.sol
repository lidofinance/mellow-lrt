// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;


import {TestHelpers, DeploymentConfiguration} from "./MainnetTestBlueprint.sol";
import {Vault} from "src/Vault.sol";
import "src/interfaces/IVault.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WithdrawalSteakhouse is TestHelpers {
    Vault public vault;

    address depositor = address(bytes20(keccak256("depositor1")));

    uint256 bondContractBalance = 0;
    uint256 depositWstethAmount = 0;
    uint256 lpAmount = 0;

    function CONFIG() public view virtual returns (DeploymentConfiguration memory) {
        return deploymentConfigurations[uint256(Deploy.STEAKHOUSE)];
    }

    function setUp() public {
        bondContractBalance = _WSTETH.balanceOf(CONFIG().wstethDefaultBond);
        vault = Vault(CONFIG().vault);

        uint256 amount = 10 ether;
        vm.deal(depositor, amount);

        vm.startPrank(depositor);
        {
            _STETH.submit{value: amount}(address(0));
            _STETH.approve(address(_WSTETH), type(uint256).max);
            depositWstethAmount = _WSTETH.wrap(amount);

            _WSTETH.approve(address(vault), type(uint256).max);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = depositWstethAmount;

            (, lpAmount) = vault.deposit(depositor, amounts, depositWstethAmount, type(uint256).max);
        }
        vm.stopPrank();
    }

    function testPreconditions() public view {
        DeploymentConfiguration memory config = CONFIG();
        assertEq(_WSTETH.balanceOf(config.wstethDefaultBond) - bondContractBalance, depositWstethAmount);
        (, uint256[] memory amounts) = vault.underlyingTvl();
        assertApproxEqAbs(depositWstethAmount, lpAmount * amounts[0] / vault.totalSupply(), 1);

        assertEq(vault.balanceOf(depositor), lpAmount);
    }

    function testSimpleWithdrawal() public {
        DeploymentConfiguration memory config = CONFIG();
        uint256[] memory minAmounts = new uint256[](1);
        minAmounts[0] = depositWstethAmount - 1; //! dust

        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        vm.startPrank(depositor);
        {
            vault.registerWithdrawal(
                depositor,
                lpAmount,
                minAmounts,
                type(uint256).max,
                type(uint256).max,
                true
            );
        }
        vm.stopPrank();

        rebase(10);

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + 1);
            assertEq(withdrawers[withdrawers.length - 1], depositor);
        }

        (bool isProcessingPossible, bool isWithdrawalsPossible, uint256[] memory expectedAmounts) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertTrue(isProcessingPossible);
        assertFalse(isWithdrawalsPossible);
        assertApproxEqAbs(expectedAmounts[0], depositWstethAmount, 1);

        vm.startPrank(config.curator);
        {
            address[] memory users = new address[](1);
            users[0] = depositor;
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength);

            assertApproxEqAbs(_WSTETH.balanceOf(depositor), depositWstethAmount, 1);
            assertApproxEqAbs(_WSTETH.balanceOf(config.wstethDefaultBond), bondContractBalance, 1);
        }
        vm.stopPrank();
    }
}

contract WithdrawalRe7 is WithdrawalSteakhouse {
    function CONFIG() public view override returns (DeploymentConfiguration memory) {
        return deploymentConfigurations[uint256(Deploy.RE7)];
    }
}

contract WithdrawalMevCap is WithdrawalSteakhouse {
    function CONFIG() public view override returns (DeploymentConfiguration memory) {
        return deploymentConfigurations[uint256(Deploy.MEVCAP)];
    }
}