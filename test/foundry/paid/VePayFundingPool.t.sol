// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../contracts/paid/VePayFundingPool.sol";
import "../mock/MockERC20.sol";

contract VePayFundingPoolTest is Test {
    VePayFundingPool public pool;
    MockERC20 public usdt;
    bytes32 public constant CALLER = keccak256("EXPERT_LOGIC_CALLER");

    function setUp() public {
        pool = new VePayFundingPool();
        usdt = new MockERC20("USDT", "USDT", 18);
    }

    function testAddRole() public {
        address newCaller = address(0x999);
        pool.addRole(newCaller);
        bool res = pool.hasRole(CALLER, newCaller);
        assertTrue(res);
    }

    function testRemoveRole() public {
        address newCaller = address(0x999);
        pool.addRole(newCaller);

        pool.removeRole(newCaller);
        bool res = pool.hasRole(CALLER, newCaller);
        assertFalse(res);
    }

    function testTransferTo() public {
        usdt.mint(address(pool), 10 * 1e18);
        pool.addRole(address(this));
        address to = address(0x12345);
        uint256 poolBalance = usdt.balanceOf(address(pool));
        assertEq(poolBalance, 10 * 1e18);
        pool.transferTo(address(usdt), to, 10 * 1e18);
        poolBalance = usdt.balanceOf(address(pool));
        assertEq(poolBalance, 0);
        uint256 userBalnace = usdt.balanceOf(to);
        assertEq(userBalnace, 10 * 1e18);
    }

    function testTransferETH() public {
        address to = address(0x789);
        pool.addRole(address(this));
        payable(address(pool)).transfer(1 ether);
        pool.transferETH(to, 1 ether);
        uint256 balance = to.balance;
        assertEq(balance, 1 ether);
    }
}
