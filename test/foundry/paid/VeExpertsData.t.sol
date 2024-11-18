// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../contracts/paid/VeExpertsData.sol";

contract VeExpertsDataTest is Test {
    VeExpertsData public expertData;
    bytes32 public constant CALLER = keccak256("EXPERT_CALLER");

    function setUp() public {
        expertData = new VeExpertsData();
    }

    function testAddRole() public {
        expertData.addRole(address(0x123));
        bool res = expertData.hasRole(CALLER, address(0x123));
        assertTrue(res);
    }

    function testInsertWithdrawInfo() public {
        expertData.addRole(address(this));
        uint256 newNonce = 1;
        // vm.expectCall(
        //     address(this),
        //     abi.encodeCall(expertData.insertWithdrawInfo, (address(0x456), newNonce, true, 2 * 1e18, address(0x101)))
        // );
        expertData.insertWithdrawInfo(
            address(0x456),
            newNonce,
            true,
            2 * 1e18,
            address(0x101)
        );
        bool result = expertData.isWithdrawn(address(0x456), newNonce);
        assertTrue(result);
    }

    function testRemoveRole() public {
        expertData.removeRole(address(0x123));
        bool res = expertData.hasRole(CALLER, address(0x123));
        assertFalse(res);
    }
}
