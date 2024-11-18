// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../contracts/paid/VeUserPayLogic.sol";
import "../../../contracts/paid/VePayFundingPool.sol";
import "../../../contracts/paid/VeUserPayData.sol";
import "../../../contracts/paid/VePayTokenProxy.sol";
import "../mock/MockERC20.sol";
import "../mock/MockERC20Permit.sol";
import "../utils/SigUtils.sol";
import "../utils/SigUtilsPay.sol";

contract VeUserPayLogicTest is Test {
    VeUserPayLogic public logic;
    VePayFundingPool public pool;
    VeUserPayData public data;
    VePayTokenProxy public proxy;
    MockERC20 public token;
    MockERC20Permit public tokenPermit;
    SigUtils public sigUtils;
    SigUtilsPay public sigUtilsPay;
    uint256 private eoaPrivateKey = 0xA11CE;
    address public signer = vm.addr(eoaPrivateKey);
    uint256 private eoaPK = 0xAAAAAC;
    address public eoa = vm.addr(eoaPK);
    address public gNosis = address(0xfffff);

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

    function _buildDomainSeparator() internal view returns (bytes32) {
        bytes32 hashedName = keccak256(bytes("VeUserPayLogic"));
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

    function setUp() public {
        data = new VeUserPayData();
        pool = new VePayFundingPool();
        proxy = new VePayTokenProxy();
        logic = new VeUserPayLogic(
            signer,
            gNosis,
            address(data),
            address(proxy),
            address(pool)
        );
        token = new MockERC20("TestToken", "TEST", 18);
        tokenPermit = new MockERC20Permit("TestTokenPermit", "TEST_PERMIT", 18);
        sigUtils = new SigUtils(_erc20DomainSeparator());
        sigUtilsPay = new SigUtilsPay(_buildDomainSeparator());
    }

    function testPaidKnowledge() public {
        uint256 amount = 0.5 * 1e18;
        uint256 projectId = 1;
        //权限配置
        data.addRole(address(logic));
        proxy.addRole(address(logic));
        //分配代币
        token.mint(address(this), amount);
        uint256 balance = token.balanceOf(address(this));
        assertEq(balance, amount);
        //授权
        token.approve(address(proxy), amount);
        uint256 allowance = token.allowance(address(this), address(proxy));
        assertEq(allowance, amount);
        //获取nonce
        uint256 nonce = 1;
        //signer 签发
        SigUtilsPay.Permit memory payPermit = SigUtilsPay.Permit({
            token: address(token),
            projectId: projectId,
            value: amount,
            spender: address(this),
            nonce: nonce,
            deadline: 1 days
        });
        bytes32 digest = sigUtilsPay.getTypedDataHash(payPermit); //0x847e7e240996c3d10a624e2362c09f76b97bed97e68b490edfda4fd47c82a5ba
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaPrivateKey, digest);
        // 付款
        logic.paidKnowledge(
            1,
            address(token),
            projectId,
            amount,
            1 days,
            v,
            r,
            s
        );
        //test 校验
        uint256 gNosisBalance = token.balanceOf(gNosis); //平台分红
        assertEq(gNosisBalance, (amount * 100) / 1000);
        uint256 forExpertBalance = token.balanceOf(address(pool));
        assertEq(forExpertBalance, (amount * 900) / 1000);
        balance = token.balanceOf(address(this));
        assertEq(balance, 0);
    }

    function testPaidKnowledgePermit() public {
        uint256 amount = 0.5 * 1e18;
        //权限配置
        data.addRole(address(logic));
        proxy.addRole(address(logic));
        //分配代币
        tokenPermit.mint(eoa, amount);
        assertEq(tokenPermit.balanceOf(eoa), amount);
        //授权
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eoa,
            spender: address(proxy),
            value: amount,
            nonce: 0,
            deadline: 1 days
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            eoaPK,
            sigUtils.getTypedDataHash(permit)
        );

        VeUserPayLogic.PermitSignature memory tokenPermitInfo = VeUserPayLogic
            .PermitSignature({deadline: 1 days, v: v, r: r, s: s});
        //获取nonce

        //签发
        SigUtilsPay.Permit memory payPermit = SigUtilsPay.Permit({
            token: address(tokenPermit),
            projectId: 1,
            value: amount,
            spender: eoa,
            nonce: 1,
            deadline: 2 days
        });
        // bytes32 digest1 = ;
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            eoaPrivateKey,
            sigUtilsPay.getTypedDataHash(payPermit)
        );
        vm.prank(eoa);
        logic.paidKnowledgePermit(
            tokenPermitInfo,
            1,
            address(tokenPermit),
            1,
            amount,
            2 days,
            v1,
            r1,
            s1
        );
        //test 校验
        uint256 gNosisBalance = tokenPermit.balanceOf(gNosis); //平台分红
        assertEq(gNosisBalance, (amount * 100) / 1000);
        uint256 forExpertBalance = tokenPermit.balanceOf(address(pool));
        assertEq(forExpertBalance, (amount * 900) / 1000);
        assertEq(tokenPermit.balanceOf(eoa), 0);
    }
}
