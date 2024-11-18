import { Contract } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import dayjs from "dayjs";

export async function commonDeploy(
  hre: HardhatRuntimeEnvironment,
  configName: string
) {
  const {
    deployments,
    getNamedAccounts,
    ethers,
    deployConfig: { contracts },
  } = hre;

  const cfg = (contracts as any)[configName];

  if (cfg.disabled) return;

  // 有地址，表示使用现有部署
  if (cfg.address) return;

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const deployArgs =
    "function" == typeof cfg.deploy
      ? cfg.deploy(await buildDeployContext(hre))
      : cfg.deploy;

  console.log(
    `deploying ${cfg.name} with`,
    deployArgs.map((i: any) => JSON.stringify(i)).join(", ")
  );

  const artifact = await deploy(cfg.name, {
    from: deployer,
    args: deployArgs,
  });

  console.log(`address: ${cfg.name}\t`, artifact.address);
  // 非新部署不再执行初始化任务
  if (!artifact.newlyDeployed) return;

  if (cfg.tasks?.length) {
    const c = new ethers.Contract(artifact.address, artifact.abi);
    const [owner] = await ethers.getSigners();
    const contract = c.connect(owner) as any;

    const ctx = await buildDeployContext(hre);
    for (const { method, args } of cfg.tasks) {
      if (method in c) {
        const methodArgs = "function" == typeof args ? args(ctx) : args;
        console.log(
          `${configName}.${method}(${methodArgs
            .map((i: any) => JSON.stringify(i))
            .join(", ")})`
        );
        const tx = await contract[method](...methodArgs);
        await tx.wait();
      } else {
        console.warn(`no method "${method}" in contract ${cfg.name}`);
      }
    }
  }

  return {
    artifact,
    deployer,
  };
}

async function buildDeployContext({
  deployments,
  deployConfig,
}: HardhatRuntimeEnvironment) {
  // TODO: 合约包含了地址，则应当获取部署的地址
  const ctx = {
    contracts: await deployments.all(),
    values: deployConfig.values,
  };
  return ctx;
}

export function datetime(expression: string) {
  const ms = dayjs(expression).valueOf();
  return Math.floor(ms / 1000);
}
