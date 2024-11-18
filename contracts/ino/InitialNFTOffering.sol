//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
___   _   _    ___            _   _   _____   _____
|_ _| | \ | |  /_ \          | \ | | |  ___| |_   _|
| |  |  \| | | | | |  _____  |  \| | | |_      | |
| |  | |\  | | |_| | |_____| | |\  | |  _|     | |
|___| |_| \_|  \___/         |_| \_| |_|       |_|


*/

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./INOTransferHelper.sol";
import "../utils/UniSwapV2.sol";
import "../utils/Error.sol";
import "../access/DAORole.sol";
import "../interfaces/access/IDAOPosition.sol";

contract InitialNFTOffering is UniSwapV2, ReentrancyGuard, DAORole {
    using SafeERC20 for IERC20;

    struct INOInfo {
        address collectionAddress; //token address
        address tokenSupply; //Token provides address
        address payToken; //Tokens paid
        address starAddress; //Scouting address
        address pmAddress; //Project party address
        uint256 totalSales; //The total amount
        uint256 takeTimes; //Number of settlements
        uint256 maxBundle; //Maximum number of lots to buy
        uint256 startTime; //Starting time
        uint256 duration; //Length of fundraising
        uint256 proxyRate; //Agent commission accuracy 10000 10% pass 1000
        uint256 starRate; //Star scout commission accuracy 10000
    }
    struct UserInfo {
        uint256[] tokenIds; //todo: purchased token id
        uint256 totalPay; //total payment
    }
    struct PMInfo {
        uint256 hasSales; //sold
        uint256 earned; //Earn fees
        uint256 hasTakeNum; //already settled
        uint256 starReward; //Star scout dividends
        uint256 platformFee; //Platform fees
        uint256 takeTimes; //Number of times to receive
    }
    struct ProxyInfo {
        bool isSettle; //Whether it has been settled
        uint256 reward; //award
    }
    mapping(uint256 => INOInfo) public inoInfo; //inoinfo[project id]
    mapping(address => mapping(uint256 => UserInfo)) public userInfo; //User Info
    mapping(uint256 => PMInfo) public pmInfo; //Project party information
    mapping(address => mapping(uint256 => ProxyInfo)) public proxyInfo; //Project party information
    mapping(uint256 => uint256[]) public settleConfig; //Settlement plan
    INOTransferHelper public transferProxy; //ERC721 or ERC1155 tranfer proxy
    IDAOPosition public daoPosition; //Agent information contract (only get the proxy address)
    uint8 public constant INO = 2;
    uint256 public feeRate = 1000; //10% precision 10000

    constructor(address _transferProxy, address _router) UniSwapV2(_router) {
        transferProxy = INOTransferHelper(_transferProxy);
        settleConfig[1] = [100]; //Extract 100% at one time
        settleConfig[2] = [50, 50]; //Extract 50% twice, 50%
        settleConfig[3] = [50, 30, 20]; //Extract three times 50%, 30%, 20%
    }

    //Create INO project
    function createINO(
        uint256 _projectId,
        INOInfo calldata _inoInfo,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes memory signatrue = abi.encode(_inoInfo);
        require(checkSignature(signatrue, _v, _r, _s), "invild signature");
        INOInfo storage inoInfo_ = inoInfo[_projectId];
        if (inoInfo_.collectionAddress != address(0)) revert ErrorCode(200);
        if (_inoInfo.totalSales == 0) revert ErrorCode(201);
        if (_inoInfo.startTime <= block.timestamp) revert ErrorCode(202);
        if (_inoInfo.takeTimes == 0 || _inoInfo.duration == 0)
            revert ErrorCode(203);
        if (msg.sender != inoInfo_.pmAddress) revert ErrorCode(204);
        //todo: Verify setApproveForAll to TransferProxy
        inoInfo_.collectionAddress = _inoInfo.collectionAddress;
        inoInfo_.payToken = _inoInfo.payToken;
        inoInfo_.starAddress = _inoInfo.starAddress;
        inoInfo_.pmAddress = _inoInfo.pmAddress;
        inoInfo_.totalSales = _inoInfo.totalSales;
        inoInfo_.takeTimes = _inoInfo.takeTimes;
        inoInfo_.maxBundle = _inoInfo.maxBundle;
        inoInfo_.startTime = _inoInfo.startTime;
        inoInfo_.duration = _inoInfo.duration;
        //inoInfo_.proxyRate = _inoInfo.proxyRate;
//todo emit
    }

    //User purchases
    function inoExchange(
        uint256 _projectId, ///Project id
        uint256[] calldata _tokenIds, ///Purchased token id
        uint256 _payTokenNum, ///Quantity paid (price after discount)
        bytes32 _inviteCode, ///Agent invitation code
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable nonReentrant {
        bytes memory signatrue = abi.encode(
            msg.sender,
            _projectId,
            _tokenIds,
            _payTokenNum,
            _inviteCode
        );
        require(checkSignature(signatrue, _v, _r, _s), "invild signature");
        INOInfo memory _inoInfo = inoInfo[_projectId];
        if (
            _inoInfo.startTime > block.timestamp ||
            _inoInfo.startTime + _inoInfo.duration < block.timestamp
        ) revert ErrorCode(205);
        uint256 len = _tokenIds.length;
        UserInfo storage _userInfo = userInfo[msg.sender][_projectId];
        if (len == 0 || _userInfo.tokenIds.length + len >= _inoInfo.maxBundle)
            revert ErrorCode(206);
        address proxy;
        if (_inviteCode != bytes32(0)) {
            //Query agent
            proxy = daoPosition.getProxyByCode(INO, _projectId, _inviteCode); //Find the address of the agent
            if (proxy == address(0)) revert ErrorCode(106);
        }
        //1.Payment
        if (_inoInfo.payToken == address(0)) {
            //eth
            if (msg.value < _payTokenNum) revert ErrorCode(207);
        } else {
            //is c20
            if (IERC20(_inoInfo.payToken).balanceOf(msg.sender) < _payTokenNum)
                revert ErrorCode(207);
            IERC20(_inoInfo.payToken).safeTransferFrom(
                msg.sender,
                address(this),
                _payTokenNum
            );
        }

        UserInfo storage user = userInfo[msg.sender][_projectId];
        user.totalPay = user.totalPay + _payTokenNum;
        //2. Transfer token
        for (uint i = 0; i < len; i++) {
            uint256 tokenId = _tokenIds[i];
            transferProxy.erc721safeTransferFrom(
                IERC721(_inoInfo.collectionAddress),
                _inoInfo.tokenSupply,
                msg.sender,
                tokenId
            );
            user.tokenIds.push(tokenId);
        }
        //distribute
//_delieve(_projectId, msg.sender, _payTokenNum, proxy);
        _delieve(_projectId, _payTokenNum, proxy);
        //emit
    }

    function pmWithdraw(uint256 _projectId) external {
        PMInfo storage pmLog = pmInfo[_projectId];
        INOInfo storage info = inoInfo[_projectId];
        if (info.startTime + info.duration > block.timestamp)
            revert ErrorCode(208);
        if (pmLog.takeTimes >= info.takeTimes) revert ErrorCode(209);
        if (pmLog.takeTimes == 0) {
            //TODO scout
//TODO platform
        }
        uint256 rate = settleConfig[info.takeTimes][pmLog.takeTimes];
        pmLog.takeTimes++;
        uint256 pending = (pmLog.earned * rate) / 100;
        pmLog.hasTakeNum += pending;
        _safeTranferToken(info.payToken, info.pmAddress, pending);

        //emit PMWithdraw(msg.sender, _projectId, pending, pmLog.takeTimes);
    }

    function proxyWithdraw() external {}

    function _delieve(
        uint256 _projectId,
        //address _account,
        uint256 _payNum,
        address _proxy
    ) private {
        INOInfo memory _inoInfo = inoInfo[_projectId];
        uint256 proxyReward;
        //Star scout dividends
        uint256 starReward = (_payNum * _inoInfo.starRate) / 10000;
        //Agent dividends
        if (_proxy != address(0)) {
            proxyReward = (_payNum * _inoInfo.proxyRate) / 10000;
            proxyInfo[_proxy][_projectId].reward += proxyReward;
            //emit
        }
        //Project party collects payment
        uint256 fee = (_payNum * feeRate) / 10000;
        uint256 pmNum = _payNum - starReward - proxyReward - fee;
        PMInfo storage pm = pmInfo[_projectId];
        pm.earned = pm.earned + pmNum;
        pm.platformFee = fee;
        //emit
    }

    //transfer
    function _safeTranferToken(
        address token,
        address to,
        uint256 amount
    ) private {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}
