//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
*Apply to become a project party (PM: Project Manager)
*
*/
contract ApplyDAOPosition {
    mapping(uint8 => mapping(address => bool)) private _pmActive; //Whether it is the project party
    mapping(uint8 => mapping(uint256 => address)) private _projecIdPM; //Project=》Project Party
    address public signerForPM;

    constructor() {
        signerForPM = msg.sender;
    }

    event ApplyPM(address account, uint256 projectId);

    //Apply to become a project party
    function applyPM(
        uint8 _role,
        uint256 _projectId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!_pmActive[_role][msg.sender], "this account has actived");
        require(
            _projecIdPM[_role][_projectId] == address(0),
            "you can't verify this account"
        );
        require(
            check(msg.sender, _role, _projectId, v, r, s),
            "invalid account"
        );
        _pmActive[_role][msg.sender] = true;
        _projecIdPM[_role][_projectId] = msg.sender;
        emit ApplyPM(msg.sender, _projectId);
    }

    //verify
    function check(
        address account,
        uint8 _role,
        uint256 projectId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        //require(info.endTime <= block.timestamp + 30 minutes, "Expired");
        bytes memory cat = abi.encode(account, _role, projectId);
        bytes32 hash = keccak256(cat);
        bytes32 data = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(data, v, r, s);
        return recovered == signerForPM;
    }

    //interface
    function _getProjectPMAddress(
        uint8 _role,
        uint256 _projectId
    ) internal view returns (address) {
        return _projecIdPM[_role][_projectId];
    }

    //override function

    function _editPM(
        uint8 _role,
        address _pmAddress,
        bool _status,
        uint256 _projectId
    ) internal {
        _pmActive[_role][_pmAddress] = _status;
        _projecIdPM[_role][_projectId] = _pmAddress;
    }
}
