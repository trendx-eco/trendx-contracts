import path from "path";
import fs from "fs";
import { task } from "hardhat/config";
import { Artifact } from "hardhat/types";

// 原共享类型文件名 'common.ts' 和 common 合约名冲突了需要改名
const CommonRename = "shared";

task(
  "copy-artifacts",
  "复制编译完成的 aib JSON 文件和 TypeScript 文件到目标目录"
)
  .addParam("target", "目标目录，多个目录逗号分隔")
  .setAction(async (taskArgs, hre) => {
    const dists = resolveTargetDirs(taskArgs);
    // console.log('dists', dists);
    const {
      deployConfig: { contracts },
    } = hre;

    for (const dir of dists) {
      // 增加 erc20 和 erc721 的 复制
      Object.assign(contracts, {
        ERC20: {
          name: "@openzeppelin/contracts/token/ERC20/ERC20.sol/ERC20.json",
          external: true,
        },
        ERC721: {
          name: "@openzeppelin/contracts/token/ERC721/ERC721.sol/ERC721.json",
          external: true,
        },
      });

      for (const key in contracts) {
        const c: any = contracts[key];

        const art = c.external
          ? require(path.resolve(process.cwd(), "artifacts", c.name))
          : await hre.artifacts.readArtifact(c.name);

        // console.log(key, art.contractName, art.sourceName);
        await copyAbiFile(art, path.join(dir, "abi", key + ".json"));

        const typeSource = findTypeFile(art.sourceName, art.contractName);
        if (fs.existsSync(typeSource)) {
          await copyTypeFile(typeSource, path.join(dir, "types", key + ".ts"));
        }
      }

      // copy common.ts
      fs.copyFileSync(
        path.resolve(process.cwd(), "types/common.ts"),
        path.join(dir, `types/${CommonRename}.ts`)
      );
    }
  });

async function copyAbiFile(artifact: Artifact, dest: string) {
  const json = {
    name: artifact.contractName,
    abi: artifact.abi,
  };
  fs.writeFileSync(dest, JSON.stringify(json, null, 2), "utf-8");
  // console.log('copy aib', artifact.contractName, 'to', dest);
}

async function copyTypeFile(src: string, dest: string) {
  // console.log('copy type from', src, 'to', dest);
  const txt = fs.readFileSync(src, "utf8");
  // 复制时将 common.ts 文件的引用路径进行变更
  fs.writeFileSync(
    dest,
    txt.replace(/\".*?\/common\";/, `"./${CommonRename}";`),
    "utf8"
  );
}

function resolveTargetDirs({ target = "" }, spliter = ",") {
  const base = process.cwd();
  const dists = target.split(spliter);
  return dists.map((d) => path.resolve(base, d));
}

// 首字母大写
function captilize(str: string) {
  return str[0].toUpperCase() + str.slice(1);
}

function findTypeFile(sourceName: string, contractName: string) {
  const base = process.cwd();
  const cname = captilize(contractName);

  let filename = path.resolve(base, "types", sourceName);
  if (fs.existsSync(filename)) {
    return path.join(filename, cname + ".ts");
  } else {
    const dirname = path.dirname(filename);
    return path.join(dirname, cname + ".ts");
  }
}
