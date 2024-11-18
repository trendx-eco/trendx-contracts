//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/pool/IDAOStakingPool.sol";

contract ApplyProxyPosition {
    using SafeERC20 for IERC20;
    //acting

    struct ProxyInfo {
        bool active; //Whether it is an agent
        bytes32 code; //Invitation code
    }

    mapping(uint8 => mapping(address => mapping(uint256 => ProxyInfo)))
        private _proxyInfo; //_proxyCode[role][msg.sender][projectId] = code;
    mapping(uint8 => mapping(uint256 => mapping(bytes32 => address)))
        private _proxyAccount; //role=>projectId => code => account
    mapping(uint8 => mapping(address => uint256)) private _proxyNum; //todo: total number of agents (adjusted to be the query project deadline)
    mapping(address => bool) public signerForProxy;

    uint256[] public applyNumber = [0, 0, 1, 2, 4, 8];
    address public daoToken;
    address public constant TO =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 public fee; //application fee
    IDAOStakingPool public stakingPool;

    constructor(address _dao, address _stakingPool, uint256 _fee) {
        daoToken = _dao;
        signerForProxy[msg.sender] = true;
        stakingPool = IDAOStakingPool(_stakingPool);
        fee = _fee;
    }

    event ApplyProxy(
        address account,
        uint256 projectId,
        bytes32 code,
        uint256 fee
    );

    //Apply to become an agent-712
//1:IDO,2:INO
    function applyProxy(
        uint8 _role,
        uint256 _projectId,
        bytes32 _code,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        ProxyInfo storage proxyInfo = _proxyInfo[_role][msg.sender][_projectId];
        require(!proxyInfo.active, "already active");
        require(
            _proxyNum[_role][msg.sender] < _getApplyNum(msg.sender),
            "apply num is full"
        );
        require(
            checkProxyRSV(msg.sender, _projectId, _code, v, r, s),
            "sign error"
        );
        IERC20(daoToken).safeTransferFrom(msg.sender, TO, fee);
        proxyInfo.active = true;
        proxyInfo.code = _code;
        _proxyAccount[_role][_projectId][_code] = msg.sender;
        _proxyNum[_role][msg.sender]++;
        emit ApplyProxy(msg.sender, _projectId, _code, fee);
    }

    //Query token invitation code
    function _getProxyCode(
        uint8 _role,
        address _account,
        uint256 _projectId
    ) internal view returns (bytes32) {
        return _proxyInfo[_role][_account][_projectId].code;
    }

    function _checkAddress(
        uint8 _role,
        uint256 _projectId,
        address _account
    ) internal view returns (bool) {
        return _proxyInfo[_role][_account][_projectId].active;
    }

    function _getAddressByCode(
        uint8 _role,
        uint256 _projectId,
        bytes32 _code
    ) internal view returns (address) {
        return _proxyAccount[_role][_projectId][_code];
    }

    //Check the number of projects that users can apply for
    function _getApplyNum(address _account) internal view returns (uint256) {
        uint256 level = stakingPool.getUserLevel(_account);
        return applyNumber[level];
    }

    function _getProxyNum(
        uint8 _role,
        address _account
    ) internal view returns (uint256) {
        return _proxyNum[_role][_account];
    }

    function checkProxyRSV(
        address _account,
        uint256 _projectId,
        bytes32 _code,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes memory cat = abi.encode(_account, _projectId, _code);
        bytes32 hash = keccak256(cat);
        bytes32 data = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(data, v, r, s);
        return signerForProxy[recovered];
    }
}
