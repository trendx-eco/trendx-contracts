// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Signer is Ownable {
    using SafeERC20 for IERC20;
    struct Order {
        uint256 id;
        address account;
        uint256 withdrawAmount;
        uint256 fee;
        uint256 solt;
        uint256 endTime;
        uint256 wType; //1.Team Award
        uint256 state; //1: Withdrawal has been made
    }
    mapping(uint256 => Order) public orders;
    mapping(address => uint256) public withdrawAmount;

    struct RSV {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    address public signer;
    address public feeTo;
    IERC20 public atcToken = IERC20(0xE882d8a34A288CD83D5CCAf2AD8E23af3f0f867E); //todo

    //, address _feeTo
    constructor(address _signer) {
        signer = _signer;
        // feeTo = _feeTo;
    }

    event TakeReward(
        address user,
        uint256 amount,
        uint256 fee,
        uint256 canTake,
        address signer,
        uint256 wType
    );

    // extract
    function takeReward(Order calldata info, RSV calldata sig) public {
        require(check(info, sig), "ERROR: illegal order");
        Order storage or = orders[info.id];
        require(or.id == 0, "error: invalid id");
        require(or.state == 0, "error: invalid state");
        require(info.account == _msgSender(), "error: invalid _msgSender");
        uint256 fee = (info.withdrawAmount * 2) / 100;
        uint256 canTake = info.withdrawAmount - fee;
        atcToken.safeTransfer(feeTo, fee);
        atcToken.safeTransfer(info.account, canTake);
        or.id = info.id;
        or.account = info.account;
        or.withdrawAmount = info.withdrawAmount;
        or.fee = fee;
        or.solt = info.solt;
        or.endTime = info.endTime;
        or.wType = info.wType;
        or.state = 1;
        withdrawAmount[_msgSender()] += info.withdrawAmount;
        emit TakeReward(
            info.account,
            info.withdrawAmount,
            fee,
            canTake,
            signer,
            info.wType
        );
    }

    // Inquire

    function fetchOrder(uint256 id) public view returns (Order memory) {
        return orders[id];
    }

    function getWithdrawAmount(address account) public view returns (uint256) {
        return withdrawAmount[account];
    }

    function check(
        Order calldata info,
        RSV calldata sig
    ) public view returns (bool) {
        // require(info.endTime <= block.timestamp + 30 minutes, "Expired");
        bytes memory cat = abi.encode(
            info.id,
            info.account,
            info.withdrawAmount,
            info.solt,
            info.endTime,
            info.wType
        );
        bytes32 hash = keccak256(cat);
        bytes32 data = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(data, sig.v, sig.r, sig.s);
        return recovered == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setFeeTo(address _fee) external onlyOwner {
        feeTo = _fee;
    }

    function takeOut(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(to, amount);
    }
}
