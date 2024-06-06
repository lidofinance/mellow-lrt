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

        depositors = new address[](3);
        lpAmounts = new uint256[](3);
        deposits = new uint256[](3);

        depositors[0] = address(bytes20(keccak256("depositorX")));
        depositors[1] = address(bytes20(keccak256("depositorY")));
        depositors[2] = address(bytes20(keccak256("depositorZ")));

        uint256 amount = 10 ether;

        for (uint256 i = 0; i < depositors.length; ++i) {
            deposits[i] = assignWstETH(depositors[i], amount * (i + 1));
            lpAmounts[i] = vault.deposit(depositors[i], deposits[i]);
        }
    }

    function testPreconditions() public view {
        DeploymentConfiguration memory config = CONFIG();
        assertEq(_WSTETH.balanceOf(config.wstethDefaultBond) - bondContractBalance, sum(deposits));
        (, uint256[] memory amounts) = vault.underlyingTvl();
        assertApproxEqAbs(sum(deposits), sum(lpAmounts) * amounts[0] / vault.totalSupply(), 1);

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
            assertApproxEqAbs(_WSTETH.balanceOf(config.wstethDefaultBond), bondContractBalance + deposits[1] + deposits[2], 1);
        }
        vm.stopPrank();
    }

    function testProcessStraight() public {
        DeploymentConfiguration memory config = CONFIG();
        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        for (uint256 i = 0; i < depositors.length; ++i) {
             vault.withdrawal(depositors[i], lpAmounts[i], deposits[i] - 2); //! dust intensyfies
        }

        rebase(10);

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + 3);
            assertEq(withdrawers[withdrawers.length - 1], depositors[2]);
            assertEq(withdrawers[withdrawers.length - 2], depositors[1]);
            assertEq(withdrawers[withdrawers.length - 3], depositors[0]);
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
            assertApproxEqAbs(expectedAmounts[0], deposits[i], 2); // !wtf it is 2
        }

        vm.startPrank(config.curator);

        uint256 bondContractBalanceAfter = bondContractBalance + sum(deposits);
        for (uint256 i = 0; i < depositors.length; ++i) {
            address[] memory users = new address[](1);
            users[0] = depositors[i];
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + (2 - i));

            bondContractBalanceAfter -= deposits[i];

            assertApproxEqAbs(_WSTETH.balanceOf(depositors[i]), deposits[i], 1);
            assertApproxEqAbs(_WSTETH.balanceOf(config.wstethDefaultBond), bondContractBalanceAfter, deposits.length);
        }
        vm.stopPrank();
    }

    function testProcessReverse() public {
        DeploymentConfiguration memory config = CONFIG();
        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        for (uint256 i = 0; i < depositors.length; ++i) {
             vault.withdrawal(depositors[i], lpAmounts[i], deposits[i] - 2); //! dust intensyfies
        }

        rebase(10);

        vm.startPrank(config.curator);
        uint256 bondContractBalanceAfter = bondContractBalance + sum(deposits);
        for (uint256 i = depositors.length; i > 1; --i) {
            address[] memory users = new address[](1);
            users[0] = depositors[i - 1];
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + i - 1);

            bondContractBalanceAfter -= deposits[i - 1];

            assertApproxEqAbs(_WSTETH.balanceOf(depositors[i-1]), deposits[i-1], 2);
            assertApproxEqAbs(_WSTETH.balanceOf(config.wstethDefaultBond), bondContractBalanceAfter, deposits.length);
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