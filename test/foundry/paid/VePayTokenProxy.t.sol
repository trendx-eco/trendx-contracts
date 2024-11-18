// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../contracts/paid/VePayTokenProxy.sol";
import "../mock/MockERC20.sol";
import "../mock/MockERC20Permit.sol";
import "../utils/SigUtils.sol";

contract VePayTokenProxyTest is Test {
    VePayTokenProxy public proxy;
    MockERC20 public token;
    MockERC20Permit public tokenPermit;
    SigUtils public sigUtils;
    bytes32 public constant CALLER = keccak256("CALLER");

    function _erc20DomainSeparator() internal view returns (bytes32) {
        bytes32 hashedName = keccak256(bytes(tokenPermit.name()));
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
                    address(tokenPermit)
                )
            );
    }

    function setUp() public {
        proxy = new VePayTokenProxy();
        token = new MockERC20("TestToken", "TEST", 18);
        tokenPermit = new MockERC20Permit("TestTokenPermit", "TEST_PERMIT", 18);
        sigUtils = new SigUtils(_erc20DomainSeparator());
    }

    function testAddRole() public {
        address newCaller = address(0x1111);
        bool res = proxy.hasRole(CALLER, newCaller);
        assertFalse(res);
        proxy.addRole(newCaller);
        res = proxy.hasRole(CALLER, newCaller);
        assertTrue(res);
    }

    function testRemoveRole() public {
        address newCaller = address(0x111);
        proxy.addRole(newCaller);
        assertTrue(proxy.hasRole(CALLER, newCaller));
        proxy.removeRole(newCaller);
        assertFalse(proxy.hasRole(CALLER, newCaller));
    }

    function testExecute() public {
        address newSpender = address(0x889);
        token.mint(newSpender, 10 * 1e18);
        uint256 balance = token.balanceOf(newSpender);
        assertEq(balance, 10 * 1e18);
        vm.prank(newSpender);
        token.approve(address(proxy), 10 * 1e18);
        uint256 res = token.allowance(newSpender, address(proxy));
        assertEq(res, 10 * 1e18);
        // console2.log(res);
        proxy.addRole(address(this));
        address pool = address(0xaa);
        proxy.execute(address(token), newSpender, pool, 10 * 1e18);
        uint256 poolBalance = token.balanceOf(pool);
        assertEq(poolBalance, 10 * 1e18);
        balance = token.balanceOf(newSpender);
        assertEq(balance, 0);
    }

    function testExecutePermit() public {
        uint256 eoaPrivateKey = 0xA11CE;
        address eoa = vm.addr(eoaPrivateKey);
        address permitSpender = address(proxy);
        uint amountMintEoa = 1 ether;
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eoa,
            spender: permitSpender,
            value: amountMintEoa,
            nonce: 0,
            deadline: 1 days
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaPrivateKey, digest);

        // tokenPermit.permit(
        //     permit.owner,
        //     permit.spender,
        //     permit.value,
        //     permit.deadline,
        //     v,
        //     r,
        //     s
        // );

        // assertEq(tokenPermit.allowance(eoa, permitSpender), amountMintEoa);
        tokenPermit.mint(eoa, amountMintEoa);
        proxy.addRole(address(this));
        proxy.executePermit(
            address(tokenPermit),
            eoa,
            permitSpender,
            amountMintEoa,
            1 days,
            v,
            r,
            s,
            address(0xaa)
        );
        uint256 amount = tokenPermit.balanceOf(address(0xaa));
        assertEq(amount, amountMintEoa);
    }
}
