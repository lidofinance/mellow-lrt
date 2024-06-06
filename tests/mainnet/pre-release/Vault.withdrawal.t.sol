// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;


import "./MainnetTestBlueprint.sol";
import {Vault} from "src/Vault.sol";
import "src/interfaces/IVault.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WithdrawalSteakhouse is TestHelpers {
    using VaultLib for Vault;
    Vault public vault;

    address[] depositors;
    uint256[] lpAmounts;
    uint256[] deposits;

    uint256 bondContractBalance = 0;

    function CONFIG() public view virtual returns (DeploymentConfiguration memory) {
        return deploymentConfigurations[uint256(Deploy.STEAKHOUSE)];
    }

    function setUp() public {
        bondContractBalance = _WSTETH.balanceOf(CONFIG().wstethDefaultBond);
        vault = Vault(CONFIG().vault);

        uint256 num = 1200;

        depositors = new address[](num);
        lpAmounts = new uint256[](num);
        deposits = new uint256[](num);

        for (uint256 i = 0; i < depositors.length; ++i) {
            depositors[i] = address(uint160(uint256(keccak256("depositor")) + i));
        }

        uint256 amount = 0.01 ether;

        for (uint256 i = 0; i < depositors.length; ++i) {
            deposits[i] = assignWstETH(depositors[i], amount + 0.001 ether);
            lpAmounts[i] = vault.deposit(depositors[i], deposits[i]);
        }
    }

    function testPreconditions() public view {
        DeploymentConfiguration memory config = CONFIG();
        assertEq(_WSTETH.balanceOf(config.wstethDefaultBond) - bondContractBalance, sum(deposits));
        (, uint256[] memory amounts) = vault.underlyingTvl();
        assertEqOrLess(sum(lpAmounts) * amounts[0] / vault.totalSupply(), sum(deposits), deposits.length);

        assertEq(vault.balanceOf(depositors[0]), lpAmounts[0]);
        assertEq(vault.balanceOf(depositors[1]), lpAmounts[1]);
        assertEq(vault.balanceOf(depositors[2]), lpAmounts[2]);
    }

    function testSimpleWithdrawal() public {
        DeploymentConfiguration memory config = CONFIG();
        address depositor = depositors[0];
        uint256 lpAmount = lpAmounts[0];
        uint256 depositWstethAmount = deposits[0];

        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        vault.withdrawal(depositor, lpAmount, depositWstethAmount - 1); //! dust

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
        assertEqOrLess(expectedAmounts[0], depositWstethAmount, 1);

        vm.startPrank(config.curator);
        {
            address[] memory users = new address[](1);
            users[0] = depositor;
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength);

            assertEqOrLess(_WSTETH.balanceOf(depositor), depositWstethAmount, 1);
            assertEqOrLess(bondContractBalance + sum(deposits) - deposits[0], _WSTETH.balanceOf(config.wstethDefaultBond), 1);
        }
        vm.stopPrank();
    }

    function testProcessStraight() public {
        DeploymentConfiguration memory config = CONFIG();
        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        for (uint256 i = 0; i < depositors.length; ++i) {
             vault.withdrawal(depositors[i], lpAmounts[i], deposits[i] - 3); //! dust intensyfies
        }

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + deposits.length);
            for (uint256 i = 0; i < depositors.length; ++i) {
                assertEq(withdrawers[withdrawers.length - 1 - i], depositors[depositors.length - 1 - i]);
            }
        }

        IVault.ProcessWithdrawalsStack memory stack = vault.calculateStack();

        for (uint256 i = 0; i < depositors.length; ++i) {
            (bool isProcessingPossible, bool isWithdrawalsPossible, uint256[] memory expectedAmounts) = vault
                .analyzeRequest(
                    stack,
                    vault.withdrawalRequest(depositors[i])
                );
            assertTrue(isProcessingPossible);
            assertFalse(isWithdrawalsPossible);
            assertEqOrLess(expectedAmounts[0], deposits[i], 3); // !wtf it is 2
        }

        vm.startPrank(config.curator);

        uint256 bondContractBalanceAfter = bondContractBalance + sum(deposits);
        for (uint256 i = 0; i < depositors.length; ++i) {
            address[] memory users = new address[](1);
            users[0] = depositors[i];
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + (depositors.length - 1 - i));

            bondContractBalanceAfter -= deposits[i];

            assertApproxEqAbs(_WSTETH.balanceOf(depositors[i]), deposits[i], 4);
            assertEqOrLess(bondContractBalanceAfter, _WSTETH.balanceOf(config.wstethDefaultBond), deposits.length * 4);
        }
        vm.stopPrank();
    }

    function testProcessReverse() public {
        DeploymentConfiguration memory config = CONFIG();
        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        for (uint256 i = 0; i < depositors.length; ++i) {
             vault.withdrawal(depositors[i], lpAmounts[i], deposits[i] - 3); //! dust intensyfies
        }

        IVault.ProcessWithdrawalsStack memory stack = vault.calculateStack();

        for (uint256 i = 0; i < depositors.length; ++i) {
            (bool isProcessingPossible, bool isWithdrawalsPossible, uint256[] memory expectedAmounts) = vault
                .analyzeRequest(
                    stack,
                    vault.withdrawalRequest(depositors[i])
                );
            assertTrue(isProcessingPossible);
            assertFalse(isWithdrawalsPossible);
            assertEqOrLess(expectedAmounts[0], deposits[i], 3); // !wtf it is 2
        }

        vm.startPrank(config.curator);
        uint256 bondContractBalanceAfter = bondContractBalance + sum(deposits);
        for (uint256 i = depositors.length; i > 1; --i) {
            address[] memory users = new address[](1);
            users[0] = depositors[i - 1];
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + i - 1);

            bondContractBalanceAfter -= deposits[i - 1];

            assertApproxEqAbs(_WSTETH.balanceOf(depositors[i-1]), deposits[i-1], 4);
            assertEqOrLess(bondContractBalanceAfter, _WSTETH.balanceOf(config.wstethDefaultBond), deposits.length*4);
        }
        vm.stopPrank();
    }

    function assertEqOrLess(uint256 a, uint256 b, uint256 delta) public pure {
        vm.assertTrue(b >= a && b - a <= delta,
            string.concat("asssertEqOrLess: should be ", vm.toString(a), "<=", vm.toString(b)));
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