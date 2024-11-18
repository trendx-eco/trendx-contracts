// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../contracts/paid/VeUserPayData.sol";

contract VeUserPayDataTest is Test {
    VeUserPayData public data;
    bytes32 public constant CALLER = keccak256("LOGIC_CALLER");

    function setUp() public {
        data = new VeUserPayData();
    }

    function testInsertPayInfo() public {
        address account = address(0x88888);
        data.addRole(address(this));
        uint256 nonce = 1;
        data.insertPayInfo(account, 1, true, 1 ether, nonce, address(0x11));
        assertTrue(data.isPaid(account, 1));
        VeUserPayData.UserPayInfo memory info = data.payInfo(account, 1);
        assertEq(info.amount, 1 ether);
        assertTrue(info.isPaid);
        assertEq(info.orderId, nonce);
        assertEq(info.payTime, block.timestamp);
        assertEq(info.payToken, address(0x11));
    }
}
