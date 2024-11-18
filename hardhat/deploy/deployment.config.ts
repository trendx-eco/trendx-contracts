import { parseEther } from "ethers/lib/utils";
import { DeploymentConfig } from "../../hardhat/plugins/deployment-config-merge";

require("dotenv").config();

// 部署配置文件
const config: DeploymentConfig = {
  // 合约配置
  env: {
    router_address: "0x3A9679C12DfcC008Cf57bD2987c90b1CFaE8441F",
  },
  contracts: {
    dao: {
      name: "DAOToken",
      deploy: ({ owner }) => [owner.address],
    },
    pool: {
      name: "contracts/pool/DAOMintingPool.sol:DAOMintingPool",
      deploy: ({ dep }) => [dep.swap.address],
      tasks: ({ now, dep, sec }) => [
        // 添加矿池类型
        ["addmintingPoolType", sec("7day"), 10],
        ["addmintingPoolType", sec("60s"), 250],
        ["addmintingPoolType", sec("1h"), 1000],
        ["addmintingPoolType", sec("10minutes"), 500], //for airdrop
        // 添加矿池
        ["addmintingPool", dep.dao.address, 0, false],
        ["addmintingPool", dep.dao.address, 1, false],
        ["addmintingPool", dep.dao.address, 2, false],
        ["addmintingPool", dep.dao.address, 3, false],
      ],
    },
    airdrop: {
      name: "contracts/airdrop/VeDAOAirdropV2.sol:VeDAOAirdropV2",
      deploy: ({ dep }) => [dep.dao.address, dep.pool.address, 3],
      tasks: ({ dep }) => [
        ["toggleAirdrop"],
        ["pool.setMonetaryPolicy", dep.airdrop.address, true],
        // ['dao.transfer', dep.airdrop.address, parseEther('100000')],
      ],
    },
  },
  // 按顺序部署以下合约
  deploy: ["dao", "pool", "airdrop"],
};

export default config;
