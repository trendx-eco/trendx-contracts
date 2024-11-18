import { BigNumber, Contract } from "ethers";

export const BIG_ZERO = BigNumber.from(0);

export async function run<T extends Function>(func: T, ...args: any[]) {
  const tx = await func(...args);
  const rec = await tx.wait();
  const { gasUsed = BIG_ZERO, effectiveGasPrice = 1 } = rec;
  return {
    ...rec,
    // 计算 gas 费
    gas: gasUsed.mul(effectiveGasPrice),
  };
}

export async function createContractWithSigner<T extends Contract>(
  { address, abi }: any,
  ethers: any
) {
  if (!address || !abi) throw new Error(`address and abi are required`);
  const c = new ethers.Contract(address, abi);
  const [signer] = await ethers.getSigners();
  return c.connect(signer) as T;
}

export function createCliTable(options: {
  head: string[];
  colWidths: number[];
}) {
  const Table = require("cli-table");
  return new Table(options);
}

export async function getContractList(
  getLengthMethod: any,
  getItemMethod: any
) {
  const length = await getLengthMethod();
  return Promise.all(
    Array.from({ length: length.toNumber() }).map((_, i) => getItemMethod(i))
  );
}
