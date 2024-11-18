// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/paid/IVePayTokenProxy.sol";

contract VePayTokenProxy is IVePayTokenProxy, AccessControl {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    bytes32 private constant CALLER = keccak256("CALLER");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    event Excute(
        address indexed caller,
        address token,
        address from,
        address to,
        uint256 amount
    );
    event ExecutePermit(
        address indexed caller,
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline
    );

    modifier onlyCaller() {
        _checkRole(CALLER);
        _;
    }

    function execute(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyCaller {
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
        emit Excute(_msgSender(), _token, _from, _to, _amount);
    }

    function executePermit(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to
    ) external override onlyCaller {
        IERC20Permit tokenPermit = IERC20Permit(token);
        tokenPermit.safePermit(owner, spender, value, deadline, v, r, s);
        IERC20(token).safeTransferFrom(owner, to, value);
        emit ExecutePermit(
            _msgSender(),
            token,
            owner,
            spender,
            value,
            deadline
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
