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

    uint256 vaultWstethBalance;
    uint256 underlyingTvl;

    function CONFIG() public view virtual returns (DeploymentConfiguration memory) {
        return deploymentConfigurations[3];
    }

    function setUp() public {
        vault = Vault(CONFIG().vault);
        vaultWstethBalance =
            _WSTETH.balanceOf(CONFIG().wstethDefaultBond) + _WSTETH.balanceOf(address(vault));
        (, uint256[] memory amounts) = vault.underlyingTvl();
        underlyingTvl = amounts[0];

        uint256 num = 100;

        depositors = new address[](num);
        lpAmounts = new uint256[](num);
        deposits = new uint256[](num);

        for (uint256 i = 0; i < depositors.length; ++i) {
            depositors[i] = address(uint160(uint256(keccak256("depositor")) + i));
        }

        bytes32 LIMIT_POSITION = bytes32(uint256(0x09));
        vm.store(CONFIG().wstethDefaultBond, LIMIT_POSITION, bytes32(uint256(1 ether)));

        uint256 amount = 0.01 ether;

        for (uint256 i = 0; i < depositors.length; ++i) {
            deposits[i] = assignWstETH(depositors[i], amount + 0.001 ether);
            lpAmounts[i] = vault.deposit(depositors[i], deposits[i]);
        }
    }

    function testPreconditions() public view {
        DeploymentConfiguration memory config = CONFIG();

        (, uint256[] memory amounts) = vault.underlyingTvl();
        uint256 newUnderlyingTvl = amounts[0];
        assertEq(newUnderlyingTvl - underlyingTvl, sum(deposits));

        uint256 newWstETHBalance = _WSTETH.balanceOf(config.wstethDefaultBond) + _WSTETH.balanceOf(address(config.vault));
        assertEq(newWstETHBalance - vaultWstethBalance, sum(deposits));

        assertEqOrLess(sum(lpAmounts) * newUnderlyingTvl / vault.totalSupply(), sum(deposits), deposits.length * 2);

        assertEq(vault.balanceOf(depositors[0]), lpAmounts[0]);
        assertEq(vault.balanceOf(depositors[1]), lpAmounts[1]);
        assertEq(vault.balanceOf(depositors[2]), lpAmounts[2]);

        assertEq(IDefaultBond(CONFIG().wstethDefaultBond).limit(), 1 ether);
    }

    function testSimpleWithdrawal() public {
        DeploymentConfiguration memory config = CONFIG();
        address depositor = depositors[0];
        uint256 lpAmount = lpAmounts[0];
        uint256 depositWstethAmount = deposits[0];

        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        vault.withdrawal(depositor, lpAmount, depositWstethAmount - 3); //! dust

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + 1);
            assertEq(withdrawers[withdrawers.length - 1], depositor);
        }

        (bool isProcessingPossible,, uint256[] memory expectedAmounts) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertTrue(isProcessingPossible);
        assertEqOrLess(expectedAmounts[0], depositWstethAmount, 2);

        vm.startPrank(config.curator);
        {
            address[] memory users = new address[](1);
            users[0] = depositor;
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength);

            assertEqOrLess(_WSTETH.balanceOf(depositor), depositWstethAmount, 2);
             uint256 newWstETHBalance = _WSTETH.balanceOf(config.wstethDefaultBond) + _WSTETH.balanceOf(address(config.vault));
            assertEqOrLess(vaultWstethBalance + sum(deposits) - deposits[0], newWstETHBalance, 2);
        }
        vm.stopPrank();
    }

    function testProcessStraight() public {
        DeploymentConfiguration memory config = CONFIG();
        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        for (uint256 i = 0; i < depositors.length; ++i) {
             vault.withdrawal(depositors[i], lpAmounts[i], deposits[i] - 3);
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
            (bool isProcessingPossible,, uint256[] memory expectedAmounts) = vault
                .analyzeRequest(
                    stack,
                    vault.withdrawalRequest(depositors[i])
                );
            assertTrue(isProcessingPossible);
            assertEqOrLess(expectedAmounts[0], deposits[i], 3);
        }

        vm.startPrank(config.curator);

        uint256 vaultWstethBalanceAfter = vaultWstethBalance + sum(deposits);
        for (uint256 i = 0; i < depositors.length; ++i) {
            address[] memory users = new address[](1);
            users[0] = depositors[i];
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + (depositors.length - 1 - i));

            vaultWstethBalanceAfter -= deposits[i];

            assertApproxEqAbs(_WSTETH.balanceOf(depositors[i]), deposits[i], 4);
            assertEqOrLess(vaultWstethBalanceAfter,
                _WSTETH.balanceOf(config.wstethDefaultBond) + _WSTETH.balanceOf(address(vault)),
                deposits.length * 2);
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
            (bool isProcessingPossible,, uint256[] memory expectedAmounts) = vault
                .analyzeRequest(
                    stack,
                    vault.withdrawalRequest(depositors[i])
                );
            assertTrue(isProcessingPossible);
            assertEqOrLess(expectedAmounts[0], deposits[i], 3); // !wtf it is 2
        }

        vm.startPrank(config.curator);
        uint256 vaultWstethBalanceAfter = vaultWstethBalance + sum(deposits);
        for (uint256 i = depositors.length; i > 1; --i) {
            address[] memory users = new address[](1);
            users[0] = depositors[i - 1];
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + i - 1);

            vaultWstethBalanceAfter -= deposits[i - 1];

            assertApproxEqAbs(_WSTETH.balanceOf(depositors[i-1]), deposits[i-1], 4);
            assertEqOrLess(vaultWstethBalanceAfter,
                _WSTETH.balanceOf(config.wstethDefaultBond) + _WSTETH.balanceOf(address(vault)),
                deposits.length * 2);
        }
        vm.stopPrank();
    }

    function testWithdrawalWithRebases() public {
        DeploymentConfiguration memory config = CONFIG();
        uint256 withdrawersLength = vault.pendingWithdrawers().length;

        for (uint256 i = 0; i < depositors.length; ++i) {
             vault.withdrawal(depositors[i], lpAmounts[i], deposits[i] - 3);
        }

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + deposits.length);
            for (uint256 i = 0; i < depositors.length; ++i) {
                assertEq(withdrawers[withdrawers.length - 1 - i], depositors[depositors.length - 1 - i]);
            }
        }

        vm.startPrank(config.curator);
        uint256 vaultWstethBalanceAfter = vaultWstethBalance + sum(deposits);
        for (uint256 i = 0; i < depositors.length; ++i) {
            address[] memory users = new address[](1);
            users[0] = depositors[i];
            config.defaultBondStrategy.processWithdrawals(users);

            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, withdrawersLength + (depositors.length - 1 - i));

            vaultWstethBalanceAfter -= deposits[i];

            assertApproxEqAbs(_WSTETH.balanceOf(depositors[i]), deposits[i], 4);
            assertEqOrLess(vaultWstethBalanceAfter,
                _WSTETH.balanceOf(config.wstethDefaultBond) + _WSTETH.balanceOf(address(vault)),
                deposits.length * 2);

            rebase(1);
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
        return deploymentConfigurations[4];
    }
}

contract WithdrawalMevCap is WithdrawalSteakhouse {
    function CONFIG() public view override returns (DeploymentConfiguration memory) {
        return deploymentConfigurations[5];
    }
}

contract WithdrawalP2P is WithdrawalSteakhouse {
    function CONFIG() public view override returns (DeploymentConfiguration memory) {
        return deploymentConfigurations[6];
    }
}
