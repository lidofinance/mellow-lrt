// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../unit/VaultTestCommon.t.sol";
import "./MainnetTestBlueprint.sol";

contract DepositLimits is VaultTestCommon, TestHelpers {
  using SafeERC20 for IERC20;

  Vault vault;
  VaultConfigurator configurator;

  address depositor = address(bytes20(keccak256("depositor")));


  function testDepositRegularLimitScenario() external {
    initVault();
    initDepositor();

    //check configurator maximalTotalSupply
    uint256 maxTotalSupply = configurator.maximalTotalSupply();
    assertEq(maxTotalSupply, 1000 ether);

    deposit(500 ether);
    assertEq(vault.totalSupply(), 500 ether + 10 gwei);

    //limit == maxTotalSupply
    deposit(maxTotalSupply - vault.totalSupply());
    assertEq(maxTotalSupply, vault.totalSupply());

    //hit the limit
    vm.expectRevert(abi.encodeWithSignature("LimitOverflow()"));
    deposit(1 wei);

    //curator raised the limit
    setMaximalTotalSupply(maxTotalSupply + 1 wei, true);

    //deposits works after increase limit
    deposit(1 wei);
  }

  function testDepositDecreaseLimit() external {
    initVault();
    initDepositor();


    deposit(500 ether);

    //curator decrease the limit
    //cannot be less then vault.totalSupply()
    vm.expectRevert(abi.encodeWithSignature("InvalidTotalSupply()"));
    setMaximalTotalSupply(1 ether, false);

    //no revert if MaximalTotalSupply == vault.totalSupply()
    setMaximalTotalSupply(vault.totalSupply(), true);
  }

  function testFuzz_DepositLimitWithRebase(int256 deltaBP) external {
    vm.assume(deltaBP > -1000 && deltaBP < 1000 );

    initVault();
    initDepositor();

    uint256 maxTotalSupply = configurator.maximalTotalSupply();

    deposit(maxTotalSupply - vault.totalSupply() - 1 wei);
    rebase(-deltaBP);
    deposit(1 wei);
  }

  /***
   *
   * HELPERS
   *
   */

  function initVault() public {
    vault = new Vault("Mellow LRT Vault", "mLRT", admin);
    vm.startPrank(admin);
    vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
    vault.grantRole(vault.OPERATOR(), operator);
    _setUp(vault);
    vm.stopPrank();
    _initialDeposit(vault);

    configurator = VaultConfigurator(
        address(vault.configurator())
    );
  }

  function initDepositor() public {
    vm.startPrank(depositor);

    deal(Constants.WSTETH, depositor, 10000 ether);
    IERC20(Constants.WSTETH).safeIncreaseAllowance(
        address(vault),
        10000 ether
    );
    vm.stopPrank();

    //initial vault total supply
    assertEq(vault.totalSupply(), 10 gwei);
  }

  function deposit(uint256 amount) public {
    vm.startPrank(depositor);
    uint256[] memory amounts = new uint256[](3);
    amounts[0] = amount;
    vault.deposit(depositor, amounts, 1 wei, type(uint256).max);
    vm.stopPrank();
  }

  function setMaximalTotalSupply(uint256 totalSupply, bool commit) public {
    vm.startPrank(admin);
    configurator.stageMaximalTotalSupply(totalSupply);
    if (commit) {
      configurator.commitMaximalTotalSupply();
    }
    vm.stopPrank();
  }
}