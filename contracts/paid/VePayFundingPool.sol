//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VePayFundingPool is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    bytes32 private constant CALLER = keccak256("EXPERT_LOGIC_CALLER");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyCaller() {
        _checkRole(CALLER);
        _;
    }

    event ERC20Transfer(
        address from,
        address to,
        uint256 amount,
        address token
    );
    event ETHTransfer(address from, address to, uint256 amount);
    event ETHReceive(address from, address to, uint256 amount);

    function addRole(address _newCaller) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(CALLER, _newCaller);
    }

    function removeRole(
        address _newCaller
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(CALLER, _newCaller);
    }

    function transferTo(
        address token,
        address to,
        uint256 amount
    ) external onlyCaller {
        IERC20(token).safeTransfer(to, amount);
        emit ERC20Transfer(address(this), to, amount, token);
    }

    function transferETH(
        address account,
        uint256 value
    ) external nonReentrant onlyCaller {
        payable(account).transfer(value);
        emit ETHTransfer(address(this), account, value);
    }

    receive() external payable {
        emit ETHReceive(msg.sender, address(this), msg.value);
    }
}
