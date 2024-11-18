// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDAOStakingPool {
    // function getUserTotalVeDao(address who) external view returns (uint256); //获取用户总抵押veDao

    // function getTotalVeDAO() external view returns (uint256);

    // function getUserTotalStake(address who, address lpToken) external view returns (uint256);

    // function getPoolTotalStake(address lpToken) external view returns (uint256);

    function getUserLevel(address who) external view returns (uint256);

    function airdrop(address account, uint256 amount, uint256 pid) external;
}
