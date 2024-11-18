//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/pool/IDAOStakingPool.sol";

contract VeDAOAirdropV3 is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATER = keccak256("OPERATER"); //role
    bytes32 public root;

    bool public isAirdrop = false;
    IDAOStakingPool public poolAddress;
    IERC20 public daoToken; //airdrop token

    mapping(address => bool) private hasTakeAirdrop; //
    mapping(address => bool) private isSigner; //bool:isSigner[account]

    constructor(address _daoToken, address _poolAddress) {
        daoToken = IERC20(_daoToken);
        poolAddress = IDAOStakingPool(_poolAddress);
        isSigner[msg.sender] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATER, msg.sender);
    }

    event TakeAirdrop(address account, uint256 airdropNum, uint256 id);
    event AdminAirdrop(address account, uint256 airdropNum, uint256 pid);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "only Admin can call this function"
        );
        _;
    }

    modifier onlyOperaters() {
        require(
            hasRole(OPERATER, _msgSender()),
            "only Opreater can call this function"
        );
        _;
    }

    //for admin
    function adminAirdrop(
        address[] memory _accounts,
        uint256 _amount,
        uint256 _pid
    ) external onlyOperaters {
        uint256 len = _accounts.length;
        require(len > 0, "accounts is empty");
        uint256 totalAirdrop = len * _amount;
        require(
            totalAirdrop <= daoToken.balanceOf(address(this)),
            "not enough daoToken"
        );
        for (uint256 index = 0; index < len; index++) {
            address account = _accounts[index];
            _safeTransferDAO(address(poolAddress), _amount);
            poolAddress.airdrop(account, _amount, _pid);
            emit AdminAirdrop(account, _amount, _pid);
        }
    }

    //_airdropNum: the actual number of airdrops (after calculation)
//_id=> 9: Immediate withdrawal, 0: one week, 1: one month, 2: 6 months, 3: one year, 4: four years
    function takeAirdrop(
        uint256 _airdropNum,
        uint256 _id,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        require(isAirdrop, "wait for airdrop");
        require(!hasTakeAirdrop[msg.sender], "You have taken the airdrop");
        require(
            check(msg.sender, _airdropNum, _id, _v, _r, _s),
            "You are not in the whitelist"
        );
        hasTakeAirdrop[msg.sender] = true;

        if (_id == 9) {
            _safeTransferDAO(msg.sender, _airdropNum);
        } else {
            uint256 _poolTypeId = _id;
            _safeTransferDAO(address(poolAddress), _airdropNum);
            poolAddress.airdrop(_msgSender(), _airdropNum, _poolTypeId);
        }
        emit TakeAirdrop(_msgSender(), _airdropNum, _id);
    }

    function fetchAccountHasTake(
        address _account
    ) external view returns (bool) {
        return hasTakeAirdrop[_account];
    }

    function _safeTransferDAO(address to, uint256 _amount) private {
        uint256 balance = daoToken.balanceOf(address(this));
        require(balance >= _amount, "VeDAOAirdrop: balance not enough");
        daoToken.safeTransfer(to, _amount);
    }

    function check(
        address account,
        uint256 amount,
        uint256 typeId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes memory cat = abi.encode(account, amount, typeId, block.chainid);
        bytes32 hash = keccak256(cat);
        bytes32 data = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(data, v, r, s);
        return isSigner[recovered];
    }

    //modifier
//Settlement
    function claim(address token, address to) external onlyAdmin {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Error: balance is zero");
        IERC20(token).safeTransfer(to, balance);
    }

    //Add role
    function addRole(address account) external onlyAdmin {
        grantRole(OPERATER, account);
    }

    //remove character
    function removeRole(address account) external onlyAdmin {
        revokeRole(OPERATER, account);
    }

    //Enable airdrop
    function toggleAirdrop() external onlyOperaters {
        isAirdrop = !isAirdrop;
    }

    //Batch set signer
    function setSigner(
        address[] calldata lists,
        bool flag
    ) external onlyOperaters {
        uint256 len = lists.length;
        require(len > 0, "Error: empty lists");
        for (uint256 i = 0; i < len; i++) {
            address account = lists[i];
            isSigner[account] = flag;
        }
    }
}
