//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/pool/IDAOStakingPool.sol";
import "../interfaces/uniswapV2/IUniswapPair.sol";
import "../interfaces/pool/IDAOLevel.sol";

contract DAOStakingPool is IDAOStakingPool, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //Miner information
    struct UserInfo {
        uint256 amount; //Pledge quantity
        uint256 veDao; //The value corresponding to lp
        uint256 rewardDebt; //User rewards
        uint256 depositTime; //Pledge event
    }

    struct PoolInfo {
        address token; //Pledge token address
        uint256 totalStake; //The total number of pledges in the current pool
        uint256 multiple; //Multiple of dao, with 18 decimal places
        bool isLPToken; //Whether the pledged token is lp token
        bool status; //Pledge status
        uint256 lockTime; //Length 7 days, 1 month
        uint256 weight; //The weight is magnified 1000 times, 1000 such as: 1 week 0.5%=5; January: 2% = 20
    }
    struct BonusTokenInfo {
        uint256 totalBonus; //Total number of rewards
        uint256 lastBonus; //Remaining rewards
        uint256 accBonusPerShare;
        uint256 endTime;
        uint256 lastRewardTime;
        uint256 tokenPerSecond; //Dividends per second
        uint256 startTime;
        uint256 updatePoolTime;
        uint256 passBonus; //Amount of dividends already distributed
    }

    mapping(address => uint256) public userTotalVeDao; //Total user pledge value userTotalVeDao[account]
    mapping(address => uint256) public poolTotalStake; //The total number of token pool pledges poolTotalStake[token]
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; //miner[account][token address][type]
    mapping(address => mapping(address => uint256)) public userTotalToken; //The total number of user token pledges userTotalToken[user][token]
    mapping(address => BonusTokenInfo) public bonusToken; //Reward token information
    mapping(address => bool) public bonusExist; //Whether the reward token exists
    PoolInfo[] public poolInfo;
    address[] private bonusList;

    address public daoToken; //dao currency address

    uint256 private totalVeDAO; //Total global pledge amount

    mapping(address => bool) public operator; //Manage token address
    IDAOLevel public daoLevel;

    constructor(address _dao, address _daoLevel) {
        daoToken = _dao;
        operator[_msgSender()] = true;
        daoLevel = IDAOLevel(_daoLevel);
    }

    /*********************************************====== EVENT ======**************************************************/
    event AddBonusToken(address account, address token, uint256 amount);
    event SubBonusToken(address account, address token, uint256 amount);
    event CreatePool(
        address account,
        address token,
        uint256 lockTime,
        uint256 weight,
        bool isLP
    );
    event Deposit(address account, uint256 pid, uint256 amount, uint256 veDao);
    event WithdrawBonus(
        address account,
        uint256 pid,
        address bounsToken,
        uint256 bonus
    );
    event Withdraw(
        address account,
        address lpToken,
        uint256 amount,
        uint256 veDao
    );
    /*********************************************====== EVENT ======**************************************************/
/*******************************************====== MODIFIER ======*************************************************/
    modifier onlyOperator() {
        require(operator[_msgSender()], "only MonetaryPolicy can call");
        _;
    }

    /******************************************====== MODIFIER ======******************************************************/
/******************************************====== INTERFACE ======*************************************************/
//Get user level
    function getUserLevel(
        address account
    ) external view override returns (uint256) {
        uint256 veDao = userTotalVeDao[account];
        return daoLevel.getUserLevel(veDao);
    }

    //empty input port
    function airdrop(
        address _account,
        uint256 _amount,
        uint256 _pid
    ) external override onlyOperator {
        require(_account != address(0), "account is zero address");
        require(_amount > 0, "amount is zero");
        require(_pid < poolInfo.length, "pid is error");
        _deposit(_account, _pid, _amount);
    }

    /******************************************====== INTERFACE ======*************************************************/
/******************************************====== PUBLIC/EXTERNAL ======*************************************************/
//Get the total number of users veDao
    function getUserTotalVeDao(
        address account
    ) external view returns (uint256) {
        return userTotalVeDao[account];
    }

    //Get the total number of ve dao in the pool
    function getTotalVeDAO() external view returns (uint256) {
        return totalVeDAO;
    }

    //Get the total number of user pledged tokens
    function getUserTotalStake(
        address account,
        address token
    ) external view returns (uint256) {
        return userTotalToken[account][token];
    }

    //Get the total number of tokens pledged in the current contract
    function getPoolTotalStake(address token) external view returns (uint256) {
        return poolTotalStake[token];
    }

    //Get the length of the mining pool
    function getPoolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    //User pledge operation

    function deposit(uint256 _pid, uint256 _amount) external {
        //Transfer token
        address poolToken = poolInfo[_pid].token;
        IERC20(poolToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        _deposit(_msgSender(), _pid, _amount);
    }

    //gasless deposit
    function depositPermint(
        uint256 _pid,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        //Transfer token
        address poolToken = poolInfo[_pid].token;
        IERC20Permit(poolToken).permit(
            _msgSender(),
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );
        IERC20(poolToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        _deposit(_msgSender(), _pid, _amount);
    }

    //Remove staking (settlement all rewards together)
    function leave(uint256 _pid) external {
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount > 0, "nothing to leave");
        require(
            user.depositTime.add(poolInfo[_pid].lockTime) < block.timestamp,
            "lock time is not over"
        );
        //Settlement of all rewards
        uint256 len = bonusList.length;
        for (uint256 index = 0; index < len; index++) {
            uint256 acc = 0;
            uint256 pending = 0; //award
            address token = bonusList[index];
            _updateBonus(token);

            acc = bonusToken[token].accBonusPerShare;
            if (user.veDao > 0) {
                pending = user.veDao.mul(acc).div(1e18);
                if (pending > user.rewardDebt) {
                    pending = pending.sub(user.rewardDebt);
                } else {
                    pending = 0;
                }
            }
            if (pending > 0) {
                //Global reward reduction
                if (bonusToken[token].lastBonus > pending) {
                    bonusToken[token].lastBonus = bonusToken[token]
                        .lastBonus
                        .sub(pending);
                } else {
                    bonusToken[token].lastBonus = 0;
                }
                //transfer reward token to the account
                _safeTransferReward(token, _msgSender(), pending);
                emit WithdrawBonus(_msgSender(), _pid, token, pending);
            }
            user.rewardDebt = user.veDao.mul(acc).div(1e18);
        }
        uint256 userVeDAO = user.veDao;
        uint256 userAmount = user.amount;
        address poolToken = poolInfo[_pid].token;
        //Clear user pledge records
        user.amount = 0;
        user.depositTime = 0;
        user.veDao = 0;
        user.rewardDebt = 0;
        //Record user global information
        userTotalVeDao[_msgSender()] = userTotalVeDao[_msgSender()].sub(
            userVeDAO
        ); //ve knife
        userTotalToken[_msgSender()][poolToken] = userTotalToken[_msgSender()][
            poolToken
        ].sub(userAmount); //Global pledge token
//Record mining pool global information
        poolTotalStake[poolToken] = poolTotalStake[poolToken].sub(userAmount); //Pledged tokens in the global pool
        totalVeDAO = totalVeDAO.sub(userVeDAO); //Global VeDAO
//Withdraw all pledged tokens
        IERC20(poolToken).safeTransfer(_msgSender(), userAmount);
        emit Withdraw(_msgSender(), poolToken, userAmount, userVeDAO);
    }

    //Withdraw income
    function withdrawBonus(uint256 _pid) external {
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.veDao > 0, "nothing to withdraw");

        uint256 len = bonusList.length;
        for (uint256 index = 0; index < len; index++) {
            address token = bonusList[index];
            _updateBonus(token);
            uint256 acc = bonusToken[token].accBonusPerShare;
            uint256 pending = user.veDao.mul(acc).div(1e18);
            if (pending > user.rewardDebt) {
                pending = pending.sub(user.rewardDebt);
            } else {
                pending = 0;
            }
            if (pending > 0) {
                //Global reward reduction
                if (bonusToken[token].lastBonus > pending) {
                    bonusToken[token].lastBonus = bonusToken[token]
                        .lastBonus
                        .sub(pending);
                } else {
                    bonusToken[token].lastBonus = 0;
                }
                user.rewardDebt = user.veDao.mul(acc).div(1e18);
                //transfer reward token to the account
                _safeTransferReward(token, _msgSender(), pending);
                emit WithdrawBonus(_msgSender(), _pid, token, pending);
            }
        }
    }

    //Query reward income
    function pendingBonus(
        address _account,
        uint256 _pid,
        address _bonusToken
    ) public view returns (uint256) {
        BonusTokenInfo storage bonus = bonusToken[_bonusToken];
        uint256 acc = bonus.accBonusPerShare;
        UserInfo storage user = userInfo[_pid][_account];
        if (user.veDao == 0) {
            return 0;
        }
        if (totalVeDAO > 0) {
            uint256 spacingTime = _getSpacingTime(_bonusToken);
            uint256 reward = spacingTime
                .mul(bonus.tokenPerSecond)
                .mul(1e18)
                .div(totalVeDAO);
            acc = acc.add(reward);
        }
        uint256 bonusNum = user.veDao.mul(acc).div(1e18);
        if (bonusNum > user.rewardDebt) {
            return bonusNum.sub(user.rewardDebt);
        } else {
            return 0;
        }
    }

    /****************************************====== PUBLIC/EXTERNAL ======*********************************************/
/****************************************====== PRIVATE/INTERNAL ======*********************************************/
    function _deposit(
        address _account,
        uint256 _pid,
        uint256 _amount
    ) internal {
        require(_amount > 0, "amout should be greater than 0");
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.status, "pool is not open");
        UserInfo storage user = userInfo[_pid][_account];
        uint256 veDAONum = _amount.mul(pool.weight).div(1000);
        if (pool.isLPToken) {
            pool.multiple = getMultiple(daoToken, pool.token); //Must be a trading pair between dao and another token
        }
        veDAONum = veDAONum.mul(pool.multiple).div(1e18);

        uint256 len = bonusList.length;
        for (uint256 index = 0; index < len; index++) {
            address token = bonusList[index];
            _updateBonus(token);
            if (user.veDao > 0) {
                //reinvestment
                uint256 pending = user
                    .veDao
                    .mul(bonusToken[token].accBonusPerShare)
                    .div(1e18)
                    .sub(user.rewardDebt);
                if (pending > 0) {
                    //transfer reward token to the account
                    _safeTransferReward(token, _account, pending);
                    //Global reward reduction
                    if (bonusToken[token].lastBonus > pending) {
                        bonusToken[token].lastBonus = bonusToken[token]
                            .lastBonus
                            .sub(pending);
                    } else {
                        bonusToken[token].lastBonus = 0;
                    }
                }

                //Update reward debt
                uint256 endTime = bonusToken[token].endTime;
                if (block.timestamp >= endTime) {
                    //This dividend has ended or the dividend has not been reinvested
                    user.rewardDebt = user
                        .veDao
                        .add(veDAONum)
                        .mul(bonusToken[token].accBonusPerShare)
                        .div(1e18);
                } else {
                    //Dividends are still in progress
                    if (
                        bonusToken[token].accBonusPerShare > 0 &&
                        user.veDao == 0
                    ) {
                        //The current mining pool is in dividends. The user pledges for the first time
                        user.rewardDebt = veDAONum
                            .mul(bonusToken[token].accBonusPerShare)
                            .div(1e18);
                    } else {
                        //Reinvest in dividends
                        user.rewardDebt += user
                            .veDao
                            .mul(bonusToken[token].accBonusPerShare)
                            .div(1e18);
                    }
                }
            }
        }
        pool.totalStake = pool.totalStake + _amount;
        //Record user pledge information
        user.amount = user.amount.add(_amount);
        user.veDao = user.veDao.add(veDAONum);
        user.depositTime = block.timestamp;
        //Record user global information
        userTotalVeDao[_account] = userTotalVeDao[_account].add(veDAONum); //ve knife
        userTotalToken[_account][pool.token] = userTotalToken[_account][
            pool.token
        ].add(_amount); //Global pledge token
//Record mining pool global information
        poolTotalStake[pool.token] = poolTotalStake[pool.token].add(_amount); //Pledged tokens in the global pool
        totalVeDAO = totalVeDAO.add(veDAONum); //globalvedao

        emit Deposit(_account, _pid, _amount, veDAONum);
    }

    //Update dividends
    function _updateBonus(address token) private {
        uint256 totalVeDAO_ = totalVeDAO;
        if (totalVeDAO_ == 0) {
            return;
        }
        uint256 spacingTime = _getSpacingTime(token);
        uint256 reward = spacingTime
            .mul(bonusToken[token].tokenPerSecond)
            .mul(1e18)
            .div(totalVeDAO_);
        bonusToken[token].accBonusPerShare = reward.add(
            bonusToken[token].accBonusPerShare
        );

        bonusToken[token].lastRewardTime = block.timestamp;
    }

    //Judge time
    function _getSpacingTime(address bsToken) private view returns (uint256) {
        uint256 expirationTime = bonusToken[bsToken].endTime;
        uint256 lastRewardTime = bonusToken[bsToken].lastRewardTime;

        if (expirationTime >= lastRewardTime) {
            if (block.timestamp < lastRewardTime) {
                return 0;
            } else {
                if (block.timestamp <= expirationTime) {
                    return block.timestamp.sub(lastRewardTime);
                } else {
                    return expirationTime.sub(lastRewardTime);
                }
            }
        } else {
            return 0;
        }
    }

    function _safeTransferReward(
        address token,
        address to,
        uint256 amount
    ) private {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }
        IERC20(token).safeTransfer(to, amount);
    }

    /****************************************====== PRIVATE/INTERNAL ======*********************************************/
/****************************************====== ONLYOPERATOR ======*********************************************/
//Create a mining pool
    function createPool(
        address _token,
        uint256 _lockTime,
        uint256 _weight,
        bool _isLPToken
    ) external onlyOperator {
        require(_token != address(0), "token is zero address");
        require(_weight > 0, "weight must be greater zero.");
        poolInfo.push(
            PoolInfo({
                token: _token,
                totalStake: 0,
                multiple: 1e18,
                isLPToken: _isLPToken,
                status: true,
                lockTime: _lockTime,
                weight: _weight
            })
        );
        emit CreatePool(_msgSender(), _token, _lockTime, _weight, _isLPToken);
    }

    //Modify the weight and lock-up time of a certain pool
    function editPool(
        uint256 _pid,
        uint256 _newLockTime,
        uint256 _newWeight
    ) external onlyOwner {
        uint256 len = getPoolLength();
        require(len > _pid, "nothing to edit");
        PoolInfo storage pool = poolInfo[_pid];
        pool.lockTime = _newLockTime;
        pool.weight = _newWeight;
    }

    function editPoolStatus(
        uint256 _pid,
        bool _isLPToken,
        bool _status
    ) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.isLPToken = _isLPToken;
        pool.status = _status;
    }

    //Distribute rewards (distributed by the whole mining pool)
    function addBonusToken(
        address _bonusToken,
        uint256 _amount,
        uint256 _endTime
    ) external onlyOperator {
        require(_bonusToken != address(0), " bonus token is zero address");
        require(_amount > 0, " amount is zero ");
        require(_endTime > block.timestamp, " endTime must bigger than now");
        BonusTokenInfo storage bonusInfo = bonusToken[_bonusToken];
        uint256 tokenPerSecond; //Dividends per second
        uint256 passBonus; //Amount of dividends already distributed
        uint256 startTime = bonusInfo.startTime == 0
            ? block.timestamp
            : bonusInfo.startTime;
        uint256 lastRewardTime = bonusInfo.lastRewardTime == 0
            ? block.timestamp
            : bonusInfo.lastRewardTime;
        if (!bonusExist[_bonusToken]) {
            //First time reward
            bonusExist[_bonusToken] = true;
            bonusList.push(_bonusToken);
        }
        _updateBonus(_bonusToken);

        if (bonusInfo.totalBonus > 0) {
            //Repeat rewards
            require(
                _endTime > bonusInfo.endTime,
                "endTime must bigger than last endTime"
            );
            passBonus = bonusInfo.passBonus;
            if (bonusInfo.endTime > block.timestamp) {
                //The last reward is still in progress
                uint256 spacingTime = block.timestamp.sub(
                    bonusInfo.updatePoolTime
                );
                passBonus += bonusInfo.tokenPerSecond.mul(spacingTime);
            }
            uint256 newTotalBonus = _amount.add(bonusInfo.totalBonus).sub(
                passBonus
            );
            uint256 bonusTime = _endTime.sub(block.timestamp);
            tokenPerSecond = newTotalBonus.div(bonusTime);
        } else {
            //First time reward
            tokenPerSecond = _amount.div(_endTime.sub(block.timestamp));
        }
        bonusInfo.totalBonus += _amount;
        bonusInfo.lastBonus += _amount;
        bonusInfo.endTime = _endTime;
        bonusInfo.lastRewardTime = lastRewardTime;
        bonusInfo.tokenPerSecond = tokenPerSecond;
        bonusInfo.startTime = startTime;
        bonusInfo.updatePoolTime = block.timestamp;
        bonusInfo.passBonus = passBonus;
        IERC20(_bonusToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        emit AddBonusToken(_msgSender(), _bonusToken, _amount);
    }

    //Reduce dividend rewards
    function subBonusToken(
        address _bonusToken,
        uint256 _amount
    ) external onlyOperator {
        require(bonusExist[_bonusToken], "bonusToken not exist");
        require(_amount > 0, "nothing to sub");
        BonusTokenInfo storage bonusInfo = bonusToken[_bonusToken];
        require(bonusInfo.endTime > block.timestamp, "must be in progress");
        _updateBonus(_bonusToken);
        uint256 passBonus = bonusInfo.passBonus.add(
            bonusInfo.tokenPerSecond.mul(
                block.timestamp.sub(bonusInfo.updatePoolTime)
            )
        );
        uint256 leaveBonus = bonusInfo.totalBonus.sub(passBonus);
        require(
            leaveBonus >= _amount,
            "leaveBonus must be greater than _amount"
        );
        uint256 tokenPerSecond = leaveBonus.div(
            bonusInfo.endTime.sub(block.timestamp)
        );
        bonusInfo.totalBonus -= _amount;
        bonusInfo.lastBonus -= _amount;
        bonusInfo.updatePoolTime = block.timestamp;
        bonusInfo.tokenPerSecond = tokenPerSecond;
        IERC20(_bonusToken).safeTransfer(_msgSender(), _amount);
        emit SubBonusToken(_msgSender(), _bonusToken, _amount);
    }

    //Edit the level contract address (the level can be modified at any time)
    function setDAOLevel(address _new) external onlyOwner {
        daoLevel = IDAOLevel(_new);
    }

    //Edit administrator permissions
    function setOperator(address account, bool flag) external onlyOwner {
        operator[account] = flag;
    }

   /**
tokenA: Coin: DAO
token: Money: ETH USDT
reserveS: liquidity of currency
reserveD: liquidity of money
multiple: amplify 18 bits
*/
    function getMultiple(
        address token,
        address pair_
    ) public view returns (uint256) {
        require(token != address(0), "no dao address");
        (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(pair_)
            .getReserves();
        uint256 reserve = (
            IUniswapPair(address(pair_)).token0() == token ? reserve1 : reserve0
        );
        uint256 pairAmount = IUniswapPair(pair_).totalSupply();
        uint256 multiple = (reserve * 1e18) / pairAmount;
        return multiple;
    }
}
