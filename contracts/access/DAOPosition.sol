//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ApplyDAOPosition.sol";
import "./ApplyProxyPosition.sol";
import "../interfaces/access/IDAOPosition.sol";

contract DAOPosition is
    ApplyDAOPosition,
    ApplyProxyPosition,
    IDAOPosition,
    Ownable
{
    constructor(
        address _dao,
        address _stakingPool,
        uint256 _fee
    ) ApplyProxyPosition(_dao, _stakingPool, _fee) {}

    function getProjectPM(
        uint8 _role,
        uint256 _projectId
    ) external view override returns (address) {
        return _getProjectPMAddress(_role, _projectId);
    }

    function getProxyCode(
        uint8 _role,
        address _account,
        uint256 _projectId
    ) external view override returns (bytes32) {
        return _getProxyCode(_role, _account, _projectId);
    }

    function getProxyByCode(
        uint8 _role,
        uint256 _projectId,
        bytes32 _code
    ) external view override returns (address) {
        return _getAddressByCode(_role, _projectId, _code);
    }

    function getProxyNum(
        uint8 _role,
        address _account
    ) external view override returns (uint256) {
        return _getProxyNum(_role, _account);
    }

    function checkIsProxy(
        uint8 _role,
        uint256 _projectId,
        address _proxyAddress
    ) external view override returns (bool) {
        return _checkAddress(_role, _projectId, _proxyAddress);
    }

    //modifier function
    function setPMsigner(address _signer) external onlyOwner {
        signerForPM = _signer;
    }

    function setPMInfo(
        uint8 _role,
        address _pmAddress,
        bool _status,
        uint256 _projectId
    ) external onlyOwner {
        _editPM(_role, _pmAddress, _status, _projectId);
    }

    function setSignerForProxy(address _signer, bool _flag) external onlyOwner {
        signerForProxy[_signer] = _flag;
    }

    function setApplyNum(uint256[] calldata _new) external onlyOwner {
        applyNumber = _new;
    }

    function setContractAddress(
        address _newDAO,
        address _newPool
    ) external onlyOwner {
        daoToken = _newDAO;
        stakingPool = IDAOStakingPool(_newPool);
    }

    function setFee(uint256 _num) external onlyOwner {
        fee = _num;
    }
}
