//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/paid/IVeUserPayData.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VeUserPayData is IVeUserPayData, AccessControl {
    using Counters for Counters.Counter;

    struct UserPayInfo {
        bool isPaid; //Whether payment has been made
        uint256 amount; //Payment amount
        uint256 orderId; //
        uint256 payTime; //Payment time
        address payToken; //payment token
    }

    mapping(address => mapping(uint256 => UserPayInfo)) private userPayInfo; //user pay info[spend'er]

    bytes32 private constant CALLER = keccak256("LOGIC_CALLER");

    event InsertPayInfo(
        address indexed caller,
        address spender,
        uint256 projectId,
        bool isPaid,
        uint256 amount,
        uint256 orderId,
        address token
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyCaller() {
        _checkRole(CALLER);
        _;
    }

    function payInfo(
        address account,
        uint256 projectId
    ) external view returns (UserPayInfo memory) {
        return userPayInfo[account][projectId];
    }

    //Whether the project has been paid
    function isPaid(
        address account,
        uint256 projectId
    ) external view override returns (bool) {
        return userPayInfo[account][projectId].isPaid;
    }

    function insertPayInfo(
        address _account,
        uint256 _projectID,
        bool _isPaid,
        uint256 _amount,
        uint256 _orderId,
        address _payToken
    ) external override onlyCaller {
        UserPayInfo storage payLog = userPayInfo[_account][_projectID];
        payLog.isPaid = _isPaid;
        payLog.amount = _amount;
        payLog.orderId = _orderId;
        payLog.payTime = block.timestamp;
        payLog.payToken = _payToken;
        emit InsertPayInfo(
            _msgSender(),
            _account,
            _projectID,
            _isPaid,
            _amount,
            _orderId,
            _payToken
        );
    }

    function addRole(address _newCaller) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(CALLER, _newCaller);
    }

    function removeRole(
        address _newCaller
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(CALLER, _newCaller);
    }
}
