// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "../interfaces/utils/IDefaultAccessControl.sol";

contract DefaultAccessControl is
    IDefaultAccessControl,
    AccessControlEnumerable
{
    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");

    /// @notice Creates a new contract.
    /// @param admin Admin of the contract
    constructor(address admin) {
        if (admin == address(0)) revert AddressZero();

        _grantRole(OPERATOR, admin);
        _grantRole(ADMIN_ROLE, admin);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_DELEGATE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPERATOR, ADMIN_DELEGATE_ROLE);
    }

    /// @inheritdoc IDefaultAccessControl
    function isAdmin(address sender) public view returns (bool) {
        return
            hasRole(ADMIN_ROLE, sender) || hasRole(ADMIN_DELEGATE_ROLE, sender);
    }

    /// @inheritdoc IDefaultAccessControl
    function isOperator(address sender) public view returns (bool) {
        return hasRole(OPERATOR, sender);
    }

    function _requireAdmin() internal view {
        if (!isAdmin(msg.sender)) {
            revert Forbidden();
        }
    }

    function _requireAtLeastOperator() internal view {
        if (!isAdmin(msg.sender) && !isOperator(msg.sender)) {
            revert Forbidden();
        }
    }
}