// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVePayFundingPool {
    function transferTo(address token, address to, uint256 amount) external;

    function tranferETH(address account, uint256 value) external;
}
