// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVePayTokenProxy {
    function execute(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function executePermit(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to
    ) external;
}
