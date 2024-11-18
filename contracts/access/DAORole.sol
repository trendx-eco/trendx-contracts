//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract DAORole is AccessControlEnumerable {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    bytes32 public constant CALLER = keccak256("CALLER"); //contract write
    bytes32 public constant SIGNER = keccak256("SIGNER"); //signer

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Role: onlyAdmin");
        _;
    }

    modifier onlyCaller() {
        require(hasRole(CALLER, msg.sender), "Role: onlyAdmin");
        _;
    }

    function addRole(bytes32 role, address account) external onlyAdmin {
        _grantRole(role, account);
    }

    function removeRole(bytes32 role, address account) external onlyAdmin {
        _revokeRole(role, account);
    }

    function fetchRole(string memory _role) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_role));
    }

    function checkSignature(
        bytes memory _signature,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        bytes32 hash = keccak256(_signature);
        bytes32 data = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(data, _v, _r, _s);
        return hasRole(SIGNER, recovered);
    }
}
