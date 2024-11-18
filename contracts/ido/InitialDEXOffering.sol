//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
_____ _____   ____
|_   _|  __ \ /__ \
| | | |  | | |  | |
| | | |  | | |  | |
_| |_| |__| | |__| |
|_____|_____/\____/

*/

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../utils/Error.sol";
import "../access/DAORole.sol";
import "../utils/UniSwapV2.sol";
import "../interfaces/access/IDAOPosition.sol";

contract InitialDEXOffering is UniSwapV2, ReentrancyGuard, DAORole {
    using SafeERC20 for IERC20;
    //ido information
    struct IDOInfo {
        address saleToken; //Project token address
        address payToken; //User payment token contract address. address(0) represents eth (main chain currency)
        address pmAddress; //Project party address
        address starAddress; //Scouting address
        uint256 totalAmount; //The project party provides the total amount of tokens (storage with precision, parameter transmission without precision)
        uint256 takeTimes; //Number of settlements
        uint256 price; //Price (the price of one token, the parameter is passed with precision, this precision is an independent precision)
        uint256 bundle; //How much can you buy in one hand (storage with precision, parameter transmission without precision)
        uint256 maxBundle; //Maximum number of lots to buy
        uint256 proxyRate; //Discount enjoyed by the agent (1000 accuracy)
        uint256 startTime; //Starting time
        uint256 duration; //Financing duration, end time = start time + fundraising duration
    }

    //User purchase information
    struct UserOrder {
        address proxyAddress; //proxy address
        uint256 buyAmount; //The number of tokens placed by the user
        uint256 buyBundle; //The number of lots placed by the user
        uint256 payAmount; //Total payment quantity
        uint256 nonce; //Number of purchases
        uint256 withdrawNum; //The actual number of winning tickets
        uint256 refund; //Refund quantity
        uint256 hasTakeNum; //Quantity already extracted
        uint256 takeTimes; //Number of times to receive
        bool isSettle; //Whether it has been settled
    }

    struct PMLog {
        uint256 hasSale; //Quantity sold
        uint256 fundRaising; //Amount of funds raised (how much money has been collected)
        uint256 totalNum; //The amount of cash that can be withdrawn by the project (the final amount that can be withdrawn, minus agency, scout and platform fees)
        uint256 refundToken; //Return tokens (refund 0 tokens if over-raised, if not over-raised: totalAmount -hasSale)
        uint256 peoxyRewards; //Node agent total dividends
        uint256 starReward; //Scout rewards
        uint256 fee; //Platform handling fee
        uint256 hasTakeNum; //Propose quantity
        uint256 takeTimes; //Number of withdrawals
        bool isSettle; //Whether it has been settled
    }

    struct ProxyLog {
        uint256 reward; //Agent reward
        bool isSettle; //Whether it has been settled
    }

    mapping(address => bool) public supportSwapToken; //Token that supports swap
    mapping(uint256 => IDOInfo) public idoInfo; //ido information
    mapping(uint256 => PMLog) public pmInfo; //Project party information
    mapping(address => mapping(uint256 => ProxyLog)) public proxyInfo; //Agent information
    mapping(address => mapping(uint256 => UserOrder)) public userOrder; //User order
    mapping(uint256 => uint256[]) public settleConfig; //Settlement plan
    bool public autoSwap; //Automatic repurchase switch
    address public platformAddress; //Platform handling fee receiving address
    IDAOPosition public daoPosition; //Agent information contract (only get the proxy address)
    uint8 public constant IDO = 1;
    event CreateIDO(
        address indexed account,
        uint256 projectId,
        uint256 totalAmount,
        IDOInfo idoInfo
    );

    event IDOExchange(
        address indexed account,
        uint256 projectId,
        uint256 buyBundle,
        uint256 realPay,
        address proxy
    );

    event UserSettle(
        address indexed account,
        uint256 projectId,
        uint256 withdrawNum,
        uint256 refund
    );

    event UserWithdraw(
        address indexed account,
        uint256 projectId,
        uint256 withdrawNum,
        uint256 nonce
    );

    event PMSettle(
        address indexed account,
        uint256 projectId,
        uint256 totalNum,
        uint256 refund,
        uint256 fee
    );
    event PMWithdraw(
        address indexed account,
        uint256 projectId,
        uint256 withdrawNum,
        uint256 nonce
    );

    event ProxyWithdraw(
        address indexed account,
        uint256 projectId,
        uint256 num
    );

    constructor(
        address _daoPersition,
        address _router,
        address _platformAddress
    ) UniSwapV2(_router) {
        daoPosition = IDAOPosition(_daoPersition);
        settleConfig[1] = [100]; //Extract 100% at one time
        settleConfig[2] = [50, 50]; //Extract 50% twice, 50%
        settleConfig[3] = [50, 30, 20]; //Extract three times 50%, 30%, 20%
        platformAddress = _platformAddress;
    }

    //The project party creates the ido project
    function createIDO(
        uint256 _projectId,
        IDOInfo calldata _idoInfo,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        bytes memory signatrue = abi.encode(_idoInfo);
        require(checkSignature(signatrue, _v, _r, _s), "invild signature");
        if (idoInfo[_projectId].saleToken == address(0)) revert ErrorCode(100);
        if (_idoInfo.totalAmount == 0) revert ErrorCode(101);
        if (_idoInfo.startTime <= block.timestamp) revert ErrorCode(102);
        if (_idoInfo.takeTimes == 0 || _idoInfo.duration == 0)
            revert ErrorCode(103);
        if (msg.sender != _idoInfo.pmAddress) revert ErrorCode(115);
        uint256 tokenDecimals = 10 ** getTokenDecimal(_idoInfo.saleToken);
        uint256 totalAmount = _idoInfo.totalAmount * tokenDecimals;
        uint256 bundle = _idoInfo.bundle * tokenDecimals;
        IDOInfo storage info = idoInfo[_projectId];
        info.saleToken = _idoInfo.saleToken;
        info.payToken = _idoInfo.payToken;
        info.pmAddress = _idoInfo.pmAddress;
        info.starAddress = _idoInfo.starAddress;
        info.totalAmount = totalAmount;
        info.takeTimes = _idoInfo.takeTimes;
        info.price = _idoInfo.price;
        info.bundle = bundle;
        info.maxBundle = _idoInfo.maxBundle;
        info.proxyRate = _idoInfo.proxyRate;
        info.startTime = _idoInfo.startTime;
        info.duration = _idoInfo.duration;
        IERC20(_idoInfo.saleToken).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        emit CreateIDO(msg.sender, _projectId, totalAmount, _idoInfo);
    }

    ///User participation in IDO
///_amount: indicates how many lots to buy
///_inviteCode: discount code,
///Passing 0x000000000000000000000000000000000000000000000000000000000000000 means there is no discount code
    function idoExchange(
        uint256 _projectId,
        uint256 _amount,
        bytes32 _inviteCode
    ) external payable nonReentrant {
        _idoExchange(msg.sender, _projectId, _amount, _inviteCode);
    }

    function _idoExchange(
        address _account,
        uint256 _projectId,
        uint256 _amount,
        bytes32 _inviteCode
    ) internal {
        IDOInfo storage info = idoInfo[_projectId];
        UserOrder storage order = userOrder[_account][_projectId];
        uint256 endTime = info.startTime + info.duration;
        if (_amount == 0 || _amount + order.buyBundle > info.maxBundle)
            revert ErrorCode(104);
        if (info.startTime > block.timestamp || endTime < block.timestamp)
            revert ErrorCode(105);

        uint256 totalBuyNum = _amount * info.bundle;
        uint256 needPay = getCoinAmount(
            info.payToken,
            info.saleToken,
            totalBuyNum,
            info.price
        );
        address proxy = order.proxyAddress;
        //1. Determine whether there is already an agent, and calculate if there is one.
//2. If not, check if there is an invitation code.
        if (order.proxyAddress == address(0)) {
            if (_inviteCode != bytes32(0)) {
                proxy = daoPosition.getProxyByCode(
                    IDO,
                    _projectId,
                    _inviteCode
                ); //Find the address of the agent
                if (proxy == address(0)) revert ErrorCode(106);
                order.proxyAddress = proxy;
                needPay = (needPay * info.proxyRate) / 1000;
            }
        } else {
            needPay = (needPay * info.proxyRate) / 1000;
        }

        //Deduction (involving the main chain currency [note] replay attack)
        if (info.payToken == address(0)) {
            //Main chain currency transaction
            if (msg.value < needPay) revert ErrorCode(107);
        } else {
            //er c20 token trading
            IERC20(info.payToken).safeTransferFrom(
                _account,
                address(this),
                needPay
            );
        }
        //Record user order information
        order.buyAmount += totalBuyNum;
        order.buyBundle += _amount;
        order.payAmount += needPay;
        order.nonce++;
        //Record the total sales amount + record the amount of funds raised
        PMLog storage pmLog = pmInfo[_projectId];
        pmLog.hasSale += totalBuyNum;
        pmLog.fundRaising += needPay;
        //trigger event
        emit IDOExchange(_account, _projectId, _amount, needPay, proxy);
    }

    function getTokenDecimal(address token) internal view returns (uint256) {
        if (token != address(0)) {
            return IERC20Metadata(token).decimals();
        }
        return 1e18; //Main chain currency
    }

    function getCoinAmount(
        address tokenIn, //Tokens paid
        address tokenOut, //Purchased tokens
        uint256 amount, //Total amount of tokens purchased
        uint256 price //The price of one hand
    ) public view returns (uint256) {
        uint256 tokenInDecimals = 10 ** getTokenDecimal(tokenIn);
        uint256 tokenOutDecimals = 10 ** getTokenDecimal(tokenOut);
        return (amount * price * tokenInDecimals) / 1e18 / tokenOutDecimals;
    }

    //1. User settlement
    function userSettle(
        uint256 _projectId,
        uint256 _withdrawNum, //The total number of winning tickets
        uint256 _refund, //refund amount
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        IDOInfo storage info = idoInfo[_projectId];
        uint256 endTime = info.startTime + info.duration;
        if (endTime > block.timestamp) revert ErrorCode(108);
        UserOrder storage user = userOrder[msg.sender][_projectId];
        if (user.isSettle) revert ErrorCode(109);
        if (user.buyAmount == 0) revert ErrorCode(110);
        if (_withdrawNum > user.buyAmount || _refund > user.refund)
            revert ErrorCode(111);
        bytes memory signature = abi.encode(
            msg.sender,
            _projectId,
            _withdrawNum,
            _refund
        ); //Generate signature information
        require(checkSignature(signature, _v, _r, _s), "invild signature");
        user.isSettle = true;
        user.withdrawNum = _withdrawNum;
        user.refund = _refund; //One-time refund
        if (_refund > 0) {
            _safeTranferToken(info.payToken, msg.sender, _refund);
        }
        emit UserSettle(msg.sender, _projectId, _withdrawNum, _refund);
    }

    //2. User withdraws coins
    function userWithdraw(uint256 _projectId) external nonReentrant {
        UserOrder storage user = userOrder[msg.sender][_projectId];
        //Determine whether the user has settled
        if (!user.isSettle) revert ErrorCode(112);
        if (user.hasTakeNum >= user.withdrawNum) revert ErrorCode(116);
        //Determine whether the user has completed all withdrawal actions
        IDOInfo storage info = idoInfo[_projectId];
        if (user.takeTimes >= info.takeTimes) revert ErrorCode(113);
        //Calculate the number of withdrawals and query the withdrawal percentage
        uint256 rate = settleConfig[info.takeTimes][user.takeTimes];
        user.takeTimes++;
        uint256 pending = (user.withdrawNum * rate) / 100;
        user.hasTakeNum += pending;
        //transfer token
        IERC20(info.saleToken).safeTransfer(msg.sender, pending);
        emit UserWithdraw(msg.sender, _projectId, pending, user.takeTimes);
    }

    //Project Party Settlement

    function pmSettle(
        uint256 _projectId, ///Project id
        uint256 _totalNum, ///The amount that the project party can finally withdraw
        uint256 _starReward, ///Scouting rewards
        uint256 _fee, ///Platform handling fee
        address[] calldata _path, //swap path
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        PMLog storage pmLog = pmInfo[_projectId];
        if (pmLog.isSettle) revert ErrorCode(114);
        IDOInfo storage info = idoInfo[_projectId];
        if (info.startTime + info.duration > block.timestamp)
            revert ErrorCode(108);
        uint256 totalTake = getCoinAmount(
            info.payToken,
            info.saleToken,
            info.totalAmount,
            info.price
        );
        if (_totalNum > totalTake) revert ErrorCode(111); //overflow
        if (msg.sender != info.pmAddress) revert ErrorCode(115);
        bytes memory signature = abi.encode(
            msg.sender,
            _projectId,
            _totalNum,
            _starReward,
            _fee
        );
        require(checkSignature(signature, _v, _r, _s), "invild signature");
        uint256 pmRefundToken;
        if (info.totalAmount >= pmLog.hasSale) {
            //Not fully funded
            pmRefundToken = info.totalAmount - pmLog.hasSale;
        }
        pmLog.isSettle = true;
        pmLog.totalNum = _totalNum;
        pmLog.refundToken = pmRefundToken;
        //pmLog.peoxyRewards = _peoxyRewards;
        pmLog.starReward = _starReward;
        pmLog.fee = _fee;
        //TRANSFER
///1. Refund if not enough funds raised
        if (pmRefundToken > 0) {
            IERC20(info.saleToken).safeTransfer(info.pmAddress, pmRefundToken);
        }
        ///2. Star scout dividends
        if (_starReward > 0 && info.starAddress != address(0)) {
            _safeTranferToken(info.payToken, info.starAddress, _starReward);
        }
        ///3. Platform fees
        if (
            !autoSwap || _path.length == 0 || !supportSwapToken[info.payToken]
        ) {
            //Platform account
            _safeTranferToken(info.payToken, platformAddress, _fee);
        } else {
            //Repurchase
            uint256 amountOut = getAmountOuts(_fee, _path);
            if (info.payToken == address(0)) {
                autoSwapEthToTokens(_fee, platformAddress, amountOut, _path);
            } else {
                autoSwapTokens(
                    info.payToken,
                    _fee,
                    platformAddress,
                    amountOut,
                    _path
                );
            }
        }
        ///todo: 4. Agency allocation

        emit PMSettle(msg.sender, _projectId, _totalNum, pmRefundToken, _fee);
    }

    //Project side settlement (batch withdrawal) todo:access
    function pmWithdraw(uint256 _projectId) external nonReentrant {
        PMLog storage pmLog = pmInfo[_projectId];
        if (!pmLog.isSettle) revert ErrorCode(112);
        IDOInfo storage info = idoInfo[_projectId];
        if (pmLog.takeTimes >= info.takeTimes) revert ErrorCode(113);
        uint256 rate = settleConfig[info.takeTimes][pmLog.takeTimes];
        pmLog.takeTimes++;
        uint256 pending = (pmLog.totalNum * rate) / 100;
        pmLog.hasTakeNum += pending;
        _safeTranferToken(info.payToken, info.pmAddress, pending);
        emit PMWithdraw(msg.sender, _projectId, pending, pmLog.takeTimes);
    }

    //Agent income

    function proxyWithdraw(
        uint256 _projectId,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        if (!daoPosition.checkIsProxy(IDO, _projectId, msg.sender))
            revert ErrorCode(117);
        ProxyLog storage proxyLog = proxyInfo[msg.sender][_projectId];
        if (proxyLog.isSettle || proxyLog.reward > 0) revert ErrorCode(109);
        bytes memory signature = abi.encode(msg.sender, _projectId, _amount);
        require(checkSignature(signature, _v, _r, _s), "invild signature");
        proxyLog.isSettle = true;
        proxyLog.reward = _amount;
        address rewardToken = idoInfo[_projectId].payToken;
        _safeTranferToken(rewardToken, msg.sender, _amount);
        emit ProxyWithdraw(msg.sender, _projectId, _amount);
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

    receive() external payable {
        //emit
    }

    //TODO: onlyAdmin
}
