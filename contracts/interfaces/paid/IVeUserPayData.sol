// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVeUserPayData {
    function isPaid(
        address account,
        uint256 projectId
    ) external view returns (bool);

    function insertPayInfo(
        address _account,
        uint256 _projectID,
        bool _isPaid,
        uint256 _amount,
        uint256 _orderId,
        address _payToken
    ) external;
}
