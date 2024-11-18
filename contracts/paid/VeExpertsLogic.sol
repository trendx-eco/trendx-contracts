//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/paid/IVeExpertsData.sol";
import "../interfaces/paid/IVePayFundingPool.sol";

contract VeExpertsLogic is EIP712, ReentrancyGuard, Ownable {
    IVeExpertsData public data;
    mapping(address => bool) private _isSigner;
    bytes32 private constant _EXPERT_TYPEHASH =
        keccak256("Withdraw(address token,uint256 value,uint256 deadline)");
    IVePayFundingPool public fundingPool;

    event Withdraw(
        address indexed account,
        address token,
        uint256 value,
        uint256 deadline
    );

    //Withdraw income
    constructor(
        address _signer,
        address _data,
        address _fundingPool
    ) EIP712("VeExpertsLogic", "1") {
        data = IVeExpertsData(_data);
        fundingPool = IVePayFundingPool(_fundingPool);
        _isSigner[_signer] = true;
    }

    function withdraw(
        uint256 orderId,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(value > 0, "validate value");
        require(block.timestamp <= deadline, "VeExperts: expired deadline");
        bytes32 structHash = keccak256(
            abi.encode(
                _EXPERT_TYPEHASH,
                block.chainid,
                token,
                value,
                msg.sender,
                orderId,
                deadline
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(_isSigner[signer], "VeExperts: invalid signature");
        //Is the nonce expired?
        require(!data.isWithdrawn(msg.sender, orderId), "validate nonce");
        //data
        data.insertWithdrawInfo(msg.sender, orderId, true, value, token);
        //transfer
        safeTransferTo(token, msg.sender, value);
        emit Withdraw(msg.sender, token, value, deadline);
    }

    function safeTransferTo(address token, address to, uint256 amount) private {
        if (token != address(0)) {
            fundingPool.transferTo(token, to, amount);
        } else {
            fundingPool.tranferETH(to, amount);
        }
    }

    //Set signature address
    function setSigner(address _newSigner, bool flag) external onlyOwner {
        _isSigner[_newSigner] = flag;
    }

    function confContract(address _data, address _pool) external onlyOwner {
        data = IVeExpertsData(_data);
        fundingPool = IVePayFundingPool(_pool);
    }
}
