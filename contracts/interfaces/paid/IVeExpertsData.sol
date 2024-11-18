// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVeExpertsData {
    function isWithdrawn(
        address account,
        uint256 orderId
    ) external view returns (bool);

    function insertWithdrawInfo(
        address account,
        uint256 orderId,
        bool isWithdraw,
        uint256 amount,
        address withdrawToken
    ) external;
}
