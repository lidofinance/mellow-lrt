// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./MainnetTestBlueprint.sol";

contract AllRoundHappyPath is TestHelpers {
    address internal immutable DEPOSITOR = makeAddr("DEPOSITOR");

    uint256 internal depositAmount = 100 * 10 ** 18;

    function setUp() external {
        uint256 ethBalance = depositAmount;
        vm.deal(DEPOSITOR, ethBalance * 3);

        vm.startPrank(DEPOSITOR);
        _STETH.submit{value: ethBalance * 2}(address(0));
        IERC20(address(_STETH)).approve(address(_WSTETH), type(uint256).max);
        _WSTETH.wrap(ethBalance * 2);
        vm.stopPrank();
    }

    function testFork_BaseWstethDepositWithdrawalWithRabase() external {
        DeploymentConfiguration memory config = deploymentConfigurations[0];

        address[] memory users = new address[](1);
        users[0] = DEPOSITOR;

        // Deposit
        vm.startPrank(DEPOSITOR);
        IERC20(address(_WSTETH)).approve(address(config.depositWrapper), depositAmount);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = depositAmount;

        uint256 depositorWstethBalanceBefore = IERC20(address(_WSTETH)).balanceOf(DEPOSITOR);

        vm.expectEmit(true, true, false, true, address(config.vault));
        emit IVault.Deposit(DEPOSITOR, amounts, 116861303836991156599); // TODO: check lp amount
        config.depositWrapper.deposit(DEPOSITOR, address(_WSTETH), depositAmount, 0, type(uint256).max);
        uint256 depositorWstethBalanceAfterDeposit = IERC20(address(_WSTETH)).balanceOf(DEPOSITOR);

        assertApproxEqAbs(depositorWstethBalanceAfterDeposit + depositAmount, depositorWstethBalanceBefore, 2);

        // Rebase
        rebase(100);

        // Withdrawal request
        config.vault.registerWithdrawal(
            DEPOSITOR,
            config.vault.balanceOf(DEPOSITOR),
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        // Admin approve
        vm.prank(config.admin);
        config.defaultBondStrategy.processAll();

        assertApproxEqAbs(IERC20(address(_WSTETH)).balanceOf(DEPOSITOR), depositorWstethBalanceBefore, 2);
    }
}
