//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/paid/IVePayTokenProxy.sol";
import "../interfaces/paid/IVeUserPayData.sol";
import "../interfaces/paid/IVePayFundingPool.sol";

contract VeUserPayLogic is EIP712, Ownable {
    using SafeERC20 for IERC20;
    struct PayInfo {
        address payToken;
        uint256 projectId;
        uint256 value;
        uint256 deadline;
    }

    struct PermitSignature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    //0

    bytes32 private constant _PAID_TYPEHASH =
        keccak256(
            "PaidKnowledge(address payToken,uint256 projectId,uint256 value,uint256 deadline)"
        );

    uint256 private forExperts = 900; //configuration
    uint256 private forGNosis = 100; //configuration
    IVeUserPayData public dataContract; //configuration
    IVePayTokenProxy public tokenProxy; //configuration
    IVePayFundingPool public fundingPool; //configuration
    address public gNosis; //configuration
    mapping(address => bool) private _isSigner; //configuration

    event PaidKnowledge(
        address indexed spender,
        address payToken,
        uint256 projectId,
        uint256 value,
        uint256 deadline
    );
    event PaidKnowledgePermit(
        address indexed spender,
        address payToken,
        uint256 projectId,
        uint256 value,
        uint256 deadline
    );

    constructor(
        address _signer,
        address _gNosis,
        address _data,
        address _proxy,
        address _pool
    ) EIP712("VeUserPayLogic", "1") {
        gNosis = _gNosis;
        dataContract = IVeUserPayData(_data);
        tokenProxy = IVePayTokenProxy(_proxy);
        fundingPool = IVePayFundingPool(_pool);
        _isSigner[_signer] = true;
    }

    function paidKnowledge(
        uint256 orderId,
        address payToken,
        uint256 projectId,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(block.timestamp <= deadline, "VeUserPay: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PAID_TYPEHASH,
                block.chainid,
                payToken,
                projectId,
                value,
                msg.sender,
                orderId,
                deadline
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(checkSigner(signer), "VeUserPay: invalid signature");
        //logic
//1. Have you paid the fee?
        require(!dataContract.isPaid(msg.sender, projectId), "Already paid");
        //2. Deduction
        _checkoutCounter(payToken, msg.sender, value);
        //3. Store data
        _insertData(projectId, value, orderId, payToken);
        //4. Generate event
        emit PaidKnowledge(msg.sender, payToken, projectId, value, deadline);
    }

    function paidKnowledgePermit(
        PermitSignature calldata signature,
        uint256 orderId,
        address payToken,
        uint256 projectId,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        //common logic
        require(block.timestamp <= deadline, "VeUserPay: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PAID_TYPEHASH,
                block.chainid,
                payToken,
                projectId,
                value,
                msg.sender,
                orderId,
                deadline
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(checkSigner(signer), "VeUserPay: invalid signature");
        //1. Have you paid the fee?
        require(!dataContract.isPaid(msg.sender, projectId), "Already paid");
        //2. pay
        _payPermit(signature, value, payToken);
        //3. Store data
        _insertData(projectId, value, orderId, payToken);
        //4. Generate event
        emit PaidKnowledgePermit(
            msg.sender,
            payToken,
            projectId,
            value,
            deadline
        );
    }

    function _insertData(
        uint256 projectId,
        uint256 value,
        uint256 currentNonce,
        address payToken
    ) private {
        dataContract.insertPayInfo(
            msg.sender,
            projectId,
            true,
            value,
            currentNonce,
            payToken
        );
    }

    function _payPermit(
        PermitSignature calldata signature,
        uint256 value,
        address payToken
    ) private {
        if (value > 0) {
            tokenProxy.executePermit(
                payToken,
                msg.sender,
                address(tokenProxy),
                value,
                signature.deadline,
                signature.v,
                signature.r,
                signature.s,
                address(this)
            );
            IERC20(payToken).safeTransfer(
                address(fundingPool),
                (value * forExperts) / 1000
            );
            IERC20(payToken).safeTransfer(
                address(gNosis),
                (value * forGNosis) / 1000
            );
        }
    }

    function _checkoutCounter(
        address payToken,
        address account,
        uint256 value
    ) private {
        if (value > 0) {
            if (payToken != address(0)) {
                //pay by ERC20
                tokenProxy.execute(payToken, account, address(this), value);
                IERC20(payToken).safeTransfer(
                    address(fundingPool),
                    (value * forExperts) / 1000
                );
                IERC20(payToken).safeTransfer(
                    address(gNosis),
                    (value * forGNosis) / 1000
                );
            } else {
                //pay by ETH
                _refundIfOver(value, account);
                payable(address(fundingPool)).transfer(
                    (value * forExperts) / 1000
                );
                payable(gNosis).transfer((value * forGNosis) / 1000);
            }
        }
    }

    function _refundIfOver(uint256 price, address account) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(account).transfer(msg.value - price);
        }
    }

    //only owner setting

    function getFundingFlowConf() external view returns (uint256, uint256) {
        return (forExperts, forGNosis);
    }

    function checkSigner(address _addr) public view returns (bool) {
        return _isSigner[_addr];
    }

    function setRate(
        uint256 expertRate,
        uint256 gnosisRate
    ) external onlyOwner {
        forExperts = expertRate;
        forGNosis = gnosisRate;
    }

    function setContract(
        address _data,
        address _proxy,
        address _pool
    ) external onlyOwner {
        dataContract = IVeUserPayData(_data);
        tokenProxy = IVePayTokenProxy(_proxy);
        fundingPool = IVePayFundingPool(_pool);
    }

    function setGNosis(address _newGNosis) external onlyOwner {
        gNosis = _newGNosis;
    }

    function setSigner(address _signer, bool flag) external onlyOwner {
        _isSigner[_signer] = flag;
    }
}
