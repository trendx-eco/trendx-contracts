// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
// import "forge-std/console.sol";

import "../../../contracts/paid/VeExpertsData.sol";
import "../../../contracts/paid/VePayFundingPool.sol";
import "../../../contracts/paid/VeExpertsLogic.sol";
import "../utils/SigUtilsWithdraw.sol";
import "../mock/MockERC20.sol";

contract VeExpertsLogicTest is Test {
    VeExpertsLogic public logic;
    VePayFundingPool public pool;
    VeExpertsData public data;
    MockERC20 public usdt;
    uint256 private eoaPrivateKey = 0xA11CE;
    address public signer = vm.addr(eoaPrivateKey);
    SigUtilsWithdraw internal sigUtilWithdraw;
    address private eoa = vm.addr(eoaPrivateKey);

    // uint256 private permitSpenderPrivateKey;
    // address private permitSpender;

    function setUp() public {
        data = new VeExpertsData();
        pool = new VePayFundingPool();
        logic = new VeExpertsLogic(signer, address(data), address(pool));
        sigUtilWithdraw = new SigUtilsWithdraw(_buildDomainSeparator());
        usdt = new MockERC20("USDT", "USDT", 18);
        // permitSpenderPrivateKey = 0xB0B;
        // permitSpender = vm.addr(permitSpenderPrivateKey);
        data.addRole(address(logic));
        pool.addRole(address(logic));
        usdt.mint(address(pool), 10 * 1e18);
    }

    function _buildDomainSeparator() internal view returns (bytes32) {
        bytes32 hashedName = keccak256(bytes("VeExpertsLogic"));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        return
            keccak256(
                abi.encode(
                    typeHash,
                    hashedName,
                    hashedVersion,
                    block.chainid,
                    address(logic)
                )
            );
    }

    function testWithdraw() public {
        SigUtilsWithdraw.Permit memory permit = SigUtilsWithdraw.Permit({
            token: address(usdt),
            value: 10 * 1e18,
            spender: address(this),
            nonce: 1,
            deadline: 1 days
        });
        bytes32 digest = sigUtilWithdraw.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaPrivateKey, digest);
        logic.withdraw(1, address(usdt), 10 * 1e18, 1 days, v, r, s);
        uint256 balance = usdt.balanceOf(address(this));
        uint256 poolBlance = usdt.balanceOf(address(pool));
        assertEq(balance, 10 * 1e18);
        assertEq(poolBlance, 0);
    }
}
