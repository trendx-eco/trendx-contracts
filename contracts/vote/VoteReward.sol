// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract VoteReward {
    struct OrderInfo {
        uint256 projectId;
        uint256 amount;
        uint256 rewardType;
        uint256 rewardStatus;
        uint256 rewardTime;
    }

    mapping(address => mapping(uint256 => uint256)) totalWithdraw;

    function withdraw() external {}

    function getOrderInfo() public view returns (OrderInfo memory) {}
}
