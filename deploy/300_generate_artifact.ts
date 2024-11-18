import { HardhatRuntimeEnvironment } from "hardhat/types";
import fs from "fs";
import path from "path";
import { simpleGit } from "simple-git";

export default async function (hre: HardhatRuntimeEnvironment) {
  // if ('ignore') return;
  const { deployments, deployConfig } = hre;
  const networkname = deployments.getNetworkName();
  const dir = path.resolve(__dirname, "../deployments", networkname);
  const abiDir = path.join(dir, "abi");
  const lite: any = {};
  if (!fs.existsSync(abiDir)) {
    fs.mkdirSync(abiDir, { recursive: true });
  }
  for (const key of deployConfig.deploy) {
    const art = await deployments.get(key);
    if (art?.abi) {
      lite[key] = art.address;
      fs.writeFileSync(
        path.join(abiDir, `${key}.json`),
        JSON.stringify(art.abi),
        "utf8"
      );
    }
  }

  const versionInfo = await getVersion();
  lite.version = versionInfo?.hash;
  lite.date = Date.now();

  fs.writeFileSync(
    path.join(dir, "artifact.js"),
    JSON.stringify(lite, null, 2),
    "utf8"
  );
}

async function getVersion() {
  const git = simpleGit();

  const logs = await git.log({ maxCount: 1 });
  return logs.latest;
}
