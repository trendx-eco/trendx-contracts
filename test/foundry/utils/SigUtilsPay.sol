// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * NOTE: this contract comes from Foundry book: https://book.getfoundry.sh/tutorials/testing-eip712
 */

contract SigUtilsPay {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // keccak256("PaidKnowledge(address payToken,uint256 projectId,uint256 value,uint256 deadline)");
    bytes32 public constant _PAID_TYPEHASH =
        0xef0a21ab34b37a8f37860f71fe4a4e82f7a330dd966316cb6412b5af8b73407f;

    struct Permit {
        address token;
        uint256 projectId;
        uint256 value;
        address spender;
        uint256 nonce;
        uint256 deadline;
    }

    // computes the hash of a permit
    function getStructHash(
        Permit memory _permit
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _PAID_TYPEHASH,
                    block.chainid,
                    _permit.token,
                    _permit.projectId,
                    _permit.value,
                    _permit.spender,
                    _permit.nonce,
                    _permit.deadline
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(
        Permit memory _permit
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    getStructHash(_permit)
                )
            );
    }
}
