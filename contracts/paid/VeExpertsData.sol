//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../interfaces/paid/IVeExpertsData.sol";

contract VeExpertsData is IVeExpertsData, AccessControl {
    using Counters for Counters.Counter;

    //withdraw log
    struct WithdrawInfo {
        bool isWithdraw; //Whether payment has been made
        uint256 amount; //Payment amount
        uint256 withdrawTime; //Payment time
        address withdrawToken; //payment token
    }

    bytes32 private constant CALLER = keccak256("EXPERT_CALLER");
    mapping(address => mapping(uint256 => WithdrawInfo)) public withdrawInfo;

    event Insert(
        address account,
        uint256 orderId,
        bool res,
        uint256 amount,
        address token
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyCaller() {
        _checkRole(CALLER);
        _;
    }

    function addRole(address _newCaller) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(CALLER, _newCaller);
    }

    function removeRole(
        address _newCaller
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(CALLER, _newCaller);
    }

    function isWithdrawn(
        address account,
        uint256 orderId
    ) external view returns (bool) {
        return withdrawInfo[account][orderId].isWithdraw;
    }

    function insertWithdrawInfo(
        address account,
        uint256 orderId,
        bool isWithdraw,
        uint256 amount,
        address withdrawToken
    ) external onlyCaller {
        WithdrawInfo storage info = withdrawInfo[account][orderId];
        info.isWithdraw = isWithdraw;
        info.amount = amount;
        info.withdrawTime = block.timestamp;
        info.withdrawToken = withdrawToken;
        emit Insert(account, orderId, isWithdraw, amount, withdrawToken);
    }
}
