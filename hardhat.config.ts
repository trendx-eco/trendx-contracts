import fs from "fs";
import path from "path";
import readlineSync from "readline-sync";
import "@nomiclabs/hardhat-etherscan";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import { HardhatUserConfig, task } from "hardhat/config";
// import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-solhint";
// import "hardhat-contract-sizer";
import "./hardhat/register";
import { bsc, bscTestnet } from "@wagmi/chains";
import * as dotenv from "dotenv";

dotenv.config();
const networkInfos = require("@wagmi/chains");
const chainIdMap: { [key: string]: string } = {};
for (const [networkName, networkInfo] of Object.entries(networkInfos)) {
  // @ts-ignore
  chainIdMap[networkInfo.id] = networkName;
}

let privateKey: string;
let ok: string;
const getMainnetPrivateKey = () => {
  let network;
  for (const [i, arg] of Object.entries(process.argv)) {
    if (arg === "--network") {
      if (process.argv[parseInt(i) + 1] == "hardhat") {
        break;
      }
      network = parseInt(process.argv[parseInt(i) + 1]);
      console.log("Deploying Contract. ChainId:", network);
      if (network.toString() in chainIdMap && ok !== "Y") {
        ok = readlineSync.question(
          `You are trying to use ${
            chainIdMap[network.toString()]
          } network [Y/n] : `
        );
        if (ok !== "Y") {
          throw new Error("Network not allowed");
        }
      }
    }
  }

  const prodNetworks = new Set<number>([bsc.id, bscTestnet.id, 44061]);
  if (network && prodNetworks.has(network)) {
    if (privateKey) {
      return privateKey;
    }
    const keythereum = require("keythereum");

    const KEYSTORE = "./vedao-deployer-key.json";
    const PASSWORD = readlineSync.question("Password: ", {
      hideEchoBack: true,
    });
    if (PASSWORD !== "") {
      const keyObject = JSON.parse(fs.readFileSync(KEYSTORE).toString());
      privateKey =
        "0x" + keythereum.recover(PASSWORD, keyObject).toString("hex");
    } else {
      privateKey =
        "0x0000000000000000000000000000000000000000000000000000000000000001";
    }
    return privateKey;
  }
  return "0x0000000000000000000000000000000000000000000000000000000000000001";
};

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          outputSelection: {
            "*": {
              "*": ["storageLayout"],
            },
          },
        },
      },
    ],
    overrides: {},
  },
  // @ts-ignore
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
  etherscan: {
    apiKey: "API_KEY",
    customChains: [],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    } as any,
    owner: {
      default: 0,
    },
  },

  defaultNetwork: "hardhat",
  networks: {
    [bsc.id]: {
      url: bsc.rpcUrls.default.http[0],
      chainId: bsc.id,
      accounts: [getMainnetPrivateKey()],
      gas: "auto",
      gasPrice: "auto",
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ["bsc", "prod"],
      companionNetworks: {},
    },
    [bscTestnet.id]: {
      url: "https://bsc.getblock.io/01cee95d-280a-4f2c-b10f-9ea987ecd858/testnet/",
      chainId: bscTestnet.id,
      accounts: [getMainnetPrivateKey()],
      gas: "auto",
      gasPrice: "auto",
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ["bscTestnet", "prod"],
      companionNetworks: {},
    },
    [44061]: {
      url: "https://chain.testnet.pro",
      chainId: 44061,
      accounts: [getMainnetPrivateKey()],
      gas: "auto",
      gasPrice: "auto",
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ["testnet", "dev"],
      companionNetworks: {},
    },
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true,
      live: true,
      saveDeployments: true,
      tags: ["test", "local"],
    },
  },
  // contractSizer: {
  //   alphaSort: true,
  //   disambiguatePaths: true,
  //   runOnCompile: true,
  //   strict: process.env.NODE_ENV != "test",
  // only: [':IDOCoinContract', ':INOERC721Contract'],
  // },
};

export default config;
