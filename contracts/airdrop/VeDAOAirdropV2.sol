//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/pool/IDAOStakingPool.sol";

contract VeDAOAirdropV2 is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATER = keccak256("OPERATER"); //role
    bytes32 public root;

    bool public isAirdrop = false;
    bool public isValidWhitelist = true;
    IDAOStakingPool public poolAddress;
    IERC20 public daoToken; //airdrop token
    uint256 public airdropAmount = 500000 * 1e18; //airdrop amount
    uint256 public poolId;

    mapping(address => bool) private whiteList; //bool:whiteList[account]
    mapping(address => bool) private hasTakeAirdrop; //
    mapping(address => bool) private isSigner; //bool:isSigner[account]

    constructor(address _daoToken, address _poolAddress, uint256 _poolId) {
        daoToken = IERC20(_daoToken);
        poolId = _poolId;
        poolAddress = IDAOStakingPool(_poolAddress);
        isSigner[msg.sender] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATER, msg.sender);
    }

    event TakeAirdrop(address account, uint256 airdropNum);
    event AdminAirdrop(address account, uint256 airdropNum, uint256 poolId);

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
        uint256 _poolId
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
            poolAddress.airdrop(account, _amount, _poolId);
            emit AdminAirdrop(account, _amount, _poolId);
        }
    }

    function takeAirdrop(
        bool _withSign,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(isAirdrop, "wait for airdrop");
        require(!hasTakeAirdrop[msg.sender], "You have taken the airdrop");
        if (isValidWhitelist) {
            if (_withSign) {
                require(
                    check(msg.sender, _v, _r, _s),
                    "You are not in the whitelist"
                );
            } else {
                require(whiteList[msg.sender], "You are not in the whitelist");
            }
        }
        hasTakeAirdrop[msg.sender] = true;
        _safeTransferDAO(address(poolAddress), airdropAmount);
        poolAddress.airdrop(_msgSender(), airdropAmount, poolId);
        emit TakeAirdrop(_msgSender(), airdropAmount);
    }

    function fetchAccountHasTake(
        address _account
    ) external view returns (bool) {
        return hasTakeAirdrop[_account];
    }

    function fetchWhiteList(address _account) external view returns (bool) {
        return whiteList[_account];
    }

    function _safeTransferDAO(address to, uint256 _amount) private {
        uint256 balance = daoToken.balanceOf(address(this));
        require(balance >= _amount, "VeDAOAirdrop: balance not enough");
        daoToken.safeTransfer(to, _amount);
    }

    function check(
        address account,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes memory cat = abi.encode(account, block.chainid);
        bytes32 hash = keccak256(cat);
        bytes32 data = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(data, v, r, s);
        return isSigner[recovered];
    }

    //modifier
//Set the number of single airdrops
    function setAirdropAmount(
        uint256 _airdropAmount,
        uint256 _poolId
    ) external onlyOperaters {
        airdropAmount = _airdropAmount;
        poolId = _poolId;
    }

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

    //Turn on and off whitelist user verification
    function toggleWhitelistValid() external onlyOperaters {
        isValidWhitelist = !isValidWhitelist;
    }

    //Set whitelist in batches
    function setWhiteList(
        address[] memory _lists,
        bool _flag
    ) external onlyOperaters {
        uint256 len = _lists.length;
        require(len > 0, "Error: empty lists");
        for (uint256 i = 0; i < len; i++) {
            address account = _lists[i];
            whiteList[account] = _flag;
            hasTakeAirdrop[account] = false;
        }
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
