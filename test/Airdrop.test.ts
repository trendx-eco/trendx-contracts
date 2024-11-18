
import { ethers } from "hardhat";
import { expect } from "chai";
import { parseEther } from "ethers/lib/utils";
import { utils } from "ethers";

describe("Depoly Airdrop Connect ", async function () {
  it("Depoly contract and Set to operator", async function () {
    const [owner] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("AlphaDAO");
    const AlphaDAO = await Token.deploy(owner.address);
    const Level = await ethers.getContractFactory("DAOLevel");
    const DAOLevel = await Level.deploy();
    const Pool = await ethers.getContractFactory("DAOStakingPool");
    const pool = await Pool.deploy(AlphaDAO.address, DAOLevel.address);
    const Airdrop = await ethers.getContractFactory("VeDAOAirdropV3");
    const airdrop = await Airdrop.deploy(AlphaDAO.address, pool.address);
    await pool.setOperator(airdrop.address, true);
    const isOperator = await pool.operator(airdrop.address);
    expect(isOperator).to.equal(true);
  });
});

describe("Airdrop logic", async function () {
  //

  it("TakeAirdrop", async function () {
    const [owner, signer, user] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("AlphaDAO");
    const AlphaDAO = await Token.deploy(owner.address);
    const Level = await ethers.getContractFactory("DAOLevel");
    const DAOLevel = await Level.deploy();
    const Pool = await ethers.getContractFactory("DAOStakingPool");
    const pool = await Pool.deploy(AlphaDAO.address, DAOLevel.address);
    const Airdrop = await ethers.getContractFactory("VeDAOAirdropV3");
    const airdrop = await Airdrop.deploy(AlphaDAO.address, pool.address);
    await pool.setOperator(airdrop.address, true);
    //create pool for airdrop
    await pool.connect(owner).createPool(AlphaDAO.address, 86400, 10, false);
    //admin transfer some token to the airdrop contract
    await AlphaDAO.connect(owner).transfer(
      airdrop.address,
      parseEther("1000000")
    );
    //set an new signer to signatrue message
    await airdrop.setSigner([signer.address], true);
    //s
    const abi = ethers.utils.defaultAbiCoder;
    // console.log("address: ", user.address)
    // console.log("uint256: ", parseEther('10'))

    let msg = abi.encode(
      ["address", "uint256", "uint256"],
      [user.address, parseEther("10"), 0]
    );
    msg = utils.keccak256(msg);
    // const a = ethers.utils.solidityKeccak256(["string", "bytes32"], ["\x19Ethereum Signed Message:\n32", msg])
    // console.log(msg)
    let signature = await signer.signMessage(ethers.utils.arrayify(msg));
    const r = signature.slice(0, 66);
    const s = "0x" + signature.slice(66, 130);
    const v = "0x" + signature.slice(130, 132);
    let sig = ethers.utils.splitSignature(signature);
    // console.log(r, s, v)
    // console.log(sig)
    // console.log(signer.address)
    //turn on airdrop
    await airdrop.toggleAirdrop();
    await airdrop.connect(user).takeAirdrop(parseEther("10"), 0, v, r, s);
    const userInfo = await pool.userInfo(0, user.address);
    // console.log(userInfo);
    expect(userInfo.amount).to.equal(parseEther("10"));
  });
});
