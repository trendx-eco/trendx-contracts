
import { parseEther } from "ethers/lib/utils";
import { DeploymentConfig } from "../../hardhat/plugins/deployment-config-merge";

require("dotenv").config();

// 部署配置文件
const config: DeploymentConfig = {
  // 合约配置
  env: {
    expert_signer: process.env.EXPERT_SIGNER,
    user_signer: process.env.USER_SIGNER,
    gnosis_safe: process.env.GNOSIS_SAFE,
  },

  contracts: {
    dao: {
      name: "DAOPermint",
      deploy: ({ owner }) => [
        parseEther("1000000000"),
        "DAO",
        "DAO",
        owner.address,
      ],
    },
    daoLevel: {
      name: "DAOLevel",
      deploy: [],
    },
    pool: {
      name: "DAOStakingPool",
      deploy: ({ dep }) => [dep.dao.address, dep.daoLevel.address],
      tasks: [],
    },
    tokenProxy: {
      name: "VePayTokenProxy",
      deploy: ({}) => [],
    },
    fundingPool: {
      name: "VePayFundingPool",
      deploy: ({}) => [],
    },
    expertsData: {
      name: "VeExpertsData",
      deploy: ({}) => [],
    },
    userData: {
      name: "VeUserPayData",
      deploy: ({}) => [],
    },
    expertsLogic: {
      name: "VeExpertsLogic",
      deploy: ({ dep, env }) => [
        env.expert_signer,
        dep.expertsData.address,
        dep.fundingPool.address,
      ],
      tasks: ({ dep }) => [
        ["expertsData.addRole", dep.expertsLogic.address],
        ["fundingPool.addRole", dep.expertsLogic.address],
      ],
    },
    userLogic: {
      name: "VeUserPayLogic",
      deploy: ({ dep, env }) => [
        env.user_signer,
        env.gnosis_safe,
        dep.userData.address,
        dep.tokenProxy.address,
        dep.fundingPool.address,
      ],
      tasks: ({ dep }) => [
        ["userData.addRole", dep.userLogic.address],
        ["tokenProxy.addRole", dep.userLogic.address],
      ],
    },
  },

  // 按顺序部署以下合约
  deploy: [
    // "dao",
    "tokenProxy",
    "fundingPool",
    // "expertsData",
    "userData",
    // "expertsLogic",
    "userLogic",
  ],
};

export default config;
