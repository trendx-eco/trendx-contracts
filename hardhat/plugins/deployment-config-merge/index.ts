import { extendEnvironment, HardhatUserConfig, subtask } from "hardhat/config";
import deepmerge from "deepmerge";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import fs from "fs";
import path from "path";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

type Context = {
  [key: string]: any;
  env: {
    [key: string]: any;
  };
  dep: {
    [key: string]: {
      address: string;
    };
  };
  owner: SignerWithAddress;
  now(): number;
  sec(express: string): number;
};

type CmdArgs = any[] | ((ctx: Context) => any[]);

export interface DeploymentConfig {
  env: {
    [key: string]: any;
  };
  contracts: {
    [key: string]: {
      name: string;
      deploy?: CmdArgs | string;
      tasks?: Array<any[]> | ((ctx: Context) => Array<any[]>);
    };
  };
  deploy: string[];
}

declare module "hardhat/types" {
  export interface HardhatRuntimeEnvironment {
    deployConfig: DeploymentConfig;
  }
}

extendEnvironment((hre: HardhatRuntimeEnvironment) => {
  if (hre.deployments) {
    const dir = process.cwd() + "/hardhat/deploy";
    let cfg = require(dir + "/deployment.default").default;
    const { deployments } = hre;
    const networkname = deployments.getNetworkName();
    const filename = path.join(dir, `deployment.${networkname}.ts`);
    if (fs.existsSync(filename)) {
      const networkcfg = require(filename).default;
      cfg = deepmerge(cfg, networkcfg, {
        arrayMerge: (_, a2) => a2,
      });
    }
    // const network = cfg.networks[networkname];
    // if (network) {
    //   if (network?.overrides) {
    //     cfg.contracts = deepmerge(cfg.contracts, network.overrides);
    //   }
    // }
    hre.deployConfig = cfg;
  }
});
