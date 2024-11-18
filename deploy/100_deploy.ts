import { HardhatRuntimeEnvironment } from "hardhat/types";
const ms = require("ms");
import { createContractWithSigner, run } from "../hardhat/utils";

async function func(hre: HardhatRuntimeEnvironment) {
  const { deployConfig, getNamedAccounts } = hre;
  const { deploy = [], contracts } = deployConfig;

  const { deployer } = await getNamedAccounts();
  console.log("deployer", deployer);

  const steps = deploy
    .map((key: string) => (contracts[key] ? { key, ...contracts[key] } : null))
    .filter((i: any) => i);

  await generalDeploy(hre, steps);
}

export default func;

async function generalDeploy(hre: HardhatRuntimeEnvironment, steps: any[]) {
  const { ethers, getNamedAccounts, deployments, deployConfig } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  async function normalizeDeployArgs(deploy: any) {
    let args = [];
    if ("function" === typeof deploy) {
      const ctx = await buildDeployContext(hre);
      args = deploy(ctx);
    } else if (Array.isArray(deploy)) {
      args = deploy;
    }
    return args;
  }

  async function normalizeTasks(raw: any = []) {
    let tasks: any[] = raw;
    if ("function" == typeof raw) {
      const ctx = await buildDeployContext(hre);
      tasks = raw(ctx);
    }
    return tasks;
  }

  for (const step of steps) {
    const { key, name } = step;

    let artifact: any;
    if (typeof step.deploy === "string") {
      // 地址
      artifact = await deployments.getArtifact(name);
      console.log("deployed already at", step.deploy);
      const ctc = await ethers.getContractAt(name, step.deploy);
      artifact.address = ctc.address;
      //   console.log('deploying', key, name, step.deploy);
    } else {
      const deployArgs = await normalizeDeployArgs(step.deploy);
      console.log("deploying", key, name, deployArgs);
      artifact = await deploy(key, {
        contract: name,
        from: deployer,
        args: deployArgs,
      });
    }

    console.log("deployed", key, artifact.address);

    if (artifact.newlyDeployed) {
      const tasks = await normalizeTasks(step.tasks);

      const contract = await createContractWithSigner(artifact, ethers);
      if (tasks.length) {
        for (const task of tasks) {
          let head: string = "";
          let args: any[] = [];
          if (Array.isArray(task)) {
            [head, ...args] = task;
          } else if (Array.isArray(task.task)) {
            [head, ...args] = task.task;
          }
          if (head) {
            console.log("\t", key, "run", head, args);
            let current;
            // TODO: 这里的代码有点散乱，重构一下
            let [_, method] = head.split(".");
            if (method) {
              // 绝对路径
              const contractName = _;
              const cfg = deployConfig.contracts[_];
              const { name } = cfg;
              // console.log('on', _, name);
              if ("string" === typeof cfg.deploy) {
                const address = cfg.deploy;
                // console.log('external', _, address);
                current = await ethers.getContractAt(name, address);
              } else {
                const art = await deployments.get(contractName);
                if (!art) {
                  throw `not artifact found: ${name}`;
                }
                current = await createContractWithSigner(art, ethers);
              }
            } else {
              // 当前路径
              current = contract;
              method = _;
              _ = key;
            }

            if (!current[method]) {
              throw `no method : ${method} in ${_}`;
            }

            await run(current[method], ...args);
          }
        }
      }
    }
  }
}

async function buildDeployContext({
  deployments,
  deployConfig,
  ethers,
}: HardhatRuntimeEnvironment) {
  // TODO: 合约包含了地址，则应当获取部署的地址

  const env = { ...process.env, ...deployConfig.env };
  const deployed: any = await deployments.all();
  const { contracts = {} } = deployConfig;
  for (const key in contracts) {
    // 注入了地址
    if (typeof contracts[key].deploy === "string") {
      //TODO: replaced with contract instance
      deployed[key] = {
        address: contracts[key].deploy,
      };
    }
  }
  const [owner] = await ethers.getSigners();
  // TODO: dep 注入 已提供地址的合约实例
  const ctx = {
    dep: deployed,
    env,
    owner,
    sec: (express: string) => Math.floor(ms(express) / 1000),
    now: () => Math.floor(Date.now() / 1000),
  };
  return ctx;
}
