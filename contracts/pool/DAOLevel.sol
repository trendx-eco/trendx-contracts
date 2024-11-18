//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/pool/IDAOLevel.sol";

contract DAOLevel is IDAOLevel {
    uint256[] public userLevel = [0, 1, 2, 3, 4, 5];
    uint256[] public userLevelVeDao = [
        0,
        5 * 1e18,
        500 * 1e18,
        50000 * 1e18,
        500000 * 1e18,
        5000000 * 1e18
    ];
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin Can Call");
        _;
    }

    //Get user level
    function getUserLevel(
        uint256 veDao
    ) external view override returns (uint256) {
        uint256 len = userLevelVeDao.length;
        for (uint256 i = 0; i < len - 1; i++) {
            if (veDao >= userLevelVeDao[i] && veDao < userLevelVeDao[i + 1]) {
                return i;
            }
        }
        return userLevel[len - 1];
    }

    function changeLevelVeDAO(uint256 key, uint256 value) external onlyAdmin {
        userLevelVeDao[key] = value;
    }
}
