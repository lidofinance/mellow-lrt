// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../unit/VaultTestCommon.t.sol";
import "./MainnetTestBlueprint.sol";

contract DepositLimits is VaultTestCommon, TestHelpers {
  using SafeERC20 for IERC20;

  uint256 public constant Q96 = 2 ** 96;

  address vaultAdmin;
  address depositor = address(bytes20(keccak256("depositor")));


  function testDepositRegularLimitScenario() external {
    DeploymentConfiguration memory config = deploymentConfigurations[0];
    Vault vault = config.vault;
    IVaultConfigurator configurator = vault.configurator();
    vaultAdmin = config.admin;

    //check configurator maximalTotalSupply
    uint256 maxTotalSupply = configurator.maximalTotalSupply();
    assertEq(maxTotalSupply, config.maximalTotalSupply);

    address[] memory tokens = vault.underlyingTokens();
    initDepositor(vault, tokens);

    //deposit works
    deposit(vault, tokens.length, 1 ether);

    //hit the limit
    vm.expectRevert(abi.encodeWithSignature("LimitOverflow()"));
    deposit(vault, tokens.length, maxTotalSupply);

    //curator raised the limit
    //there is delay exists between stage and commit operations
    //so use vm.warp(block.timestamp + configurator.maximalTotalSupplyDelay()); before commit
    setMaximalTotalSupply(configurator, maxTotalSupply + 500 ether, true);

    //deposits works after increase limit
    deposit(vault, tokens.length, 1 ether);
  }

  function testDepositDecreaseLimit() external {
    DeploymentConfiguration memory config = deploymentConfigurations[0];
    Vault vault = config.vault;
    IVaultConfigurator configurator = vault.configurator();
    vaultAdmin = config.admin;

    address[] memory tokens = vault.underlyingTokens();
    initDepositor(vault, tokens);


    deposit(vault, tokens.length, 500 ether);

    //curator decrease the limit
    //cannot be less then vault.totalSupply()
    vm.expectRevert(abi.encodeWithSignature("InvalidTotalSupply()"));
    setMaximalTotalSupply(configurator, 1 ether, false);

    //no revert if MaximalTotalSupply == vault.totalSupply()
    setMaximalTotalSupply(configurator, vault.totalSupply(), true);
  }

  function testFuzz_DepositLimitWithRebase(int256 deltaBP) external {
    vm.assume(deltaBP > -1000 && deltaBP < 1000 );

    DeploymentConfiguration memory config = deploymentConfigurations[0];
    Vault vault = config.vault;
    IVaultConfigurator configurator = vault.configurator();
    vaultAdmin = config.admin;

    (
      address[] memory tokens,
      uint256[] memory totalAmounts
    ) = vault.underlyingTvl();
    initDepositor(vault, tokens);

    uint256 maxTotalSupply = configurator.maximalTotalSupply();

    deposit(vault, tokens.length, 1 ether);

    uint256 totalSupplyBefore = vault.totalSupply();
    uint256 totalValueBefore = getTotalValue(configurator, tokens, totalAmounts);
    rebase(deltaBP);
    uint256 totalSupplyAfter = vault.totalSupply();
    uint256 totalValueAfter = getTotalValue(configurator, tokens, totalAmounts);

    assertEq(totalSupplyBefore, totalSupplyAfter);
    // assertEq(totalValueBefore, totalValueAfter);
  }

  /***
   *
   * HELPERS
   *
   */
  function getTotalValue(
    IVaultConfigurator configurator,
    address[] memory tokens,
    uint256[] memory totalAmounts
  ) public view returns(uint256) {
    uint256 totalValue = 0;
    IPriceOracle priceOracle = IPriceOracle(configurator.priceOracle());
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 priceX96 = priceOracle.priceX96(address(configurator.vault()), tokens[i]);
      totalValue += totalAmounts[i] == 0
          ? 0
          : FullMath.mulDivRoundingUp(totalAmounts[i], priceX96, Q96);
    }

    return totalValue;
  }


  function initDepositor(Vault vault, address[] memory tokens) public {
    vm.startPrank(depositor);

    for(uint256 i=0; i< tokens.length; i++) {
      deal(tokens[i], depositor, 100000 ether);
      IERC20(tokens[i]).safeIncreaseAllowance(
          address(vault),
          100000 ether
      );
    }

    vm.stopPrank();
  }

  function deposit(Vault vault, uint256 tokenLength, uint256 amount) public {
    vm.startPrank(depositor);
    uint256[] memory amounts = new uint256[](tokenLength);
    amounts[0] = amount;
    vault.deposit(depositor, amounts, 1 wei, type(uint256).max);
    vm.stopPrank();
  }

  function setMaximalTotalSupply(IVaultConfigurator configurator, uint256 totalSupply, bool commit) public {
    vm.startPrank(vaultAdmin);
    configurator.stageMaximalTotalSupply(totalSupply);
    if (commit) {
      vm.warp(block.timestamp + configurator.maximalTotalSupplyDelay());
      configurator.commitMaximalTotalSupply();
    }
    vm.stopPrank();
  }
}