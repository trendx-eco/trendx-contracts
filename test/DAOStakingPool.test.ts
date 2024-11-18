
import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { AlphaDAO, DAOStakingPool } from "../types";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("DAOStakingPool and Deposit", function () {
  let admin: SignerWithAddress;
  let pool: DAOStakingPool;
  let DAOToken: AlphaDAO;
  let User: SignerWithAddress;
  before(async () => {
    const [owner, user1] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("AlphaDAO");
    const AlphaDAO = await Token.deploy(owner.address);
    const Level = await ethers.getContractFactory("DAOLevel");
    const DAOLevel = await Level.deploy();
    const Pool = await ethers.getContractFactory("DAOStakingPool");
    pool = (await Pool.deploy(AlphaDAO.address, DAOLevel.address)) as any;
    DAOToken = AlphaDAO as any;
    admin = owner;
    User = user1;
  });
  it("depoly and role check", async function () {
    const res = await pool.operator(admin.address);
    expect(res).to.equal(true);
  });
  it("create pool", async function () {
    await pool.connect(admin).createPool(DAOToken.address, 86400, 10, false);
    const len = await pool.getPoolLength();
    expect(len).to.equal(1);
    // const poolInfo = await pool.poolInfo(0);
    // console.log("token: ", poolInfo[0]);
    // console.log("totalStake: ", poolInfo[1]);
    // console.log("multiple: ", poolInfo[2]);
    // console.log("isLPToken: ", poolInfo[3]);
    // console.log("status: ", poolInfo[4]);
    // console.log("lockTime: ", poolInfo[5]);
    // console.log("weight: ", poolInfo[6]);
  });

  it("Deposit and Leave", async function () {
    await DAOToken.connect(admin).transfer(User.address, parseEther("1000"));
    const userBalance = await DAOToken.balanceOf(User.address);
    expect(userBalance).to.equal(parseEther("1000"));
    await DAOToken.connect(User).approve(pool.address, userBalance);
    await pool.connect(User).deposit(0, parseEther("1000"));
    // const poolInfo = await pool.poolInfo(0);
    // console.log("token: ", poolInfo[0]);
    // console.log("totalStake: ", poolInfo[1]);
    // console.log("multiple: ", poolInfo[2]);
    // console.log("isLPToken: ", poolInfo[3]);
    // console.log("status: ", poolInfo[4]);
    // console.log("lockTime: ", poolInfo[5]);
    // console.log("weight: ", poolInfo[6]);
    const userInfo = await pool.userInfo(0, User.address);
    // console.log("userInfo: ", userInfo);
    expect(userInfo[0]).to.equal(userBalance);
    await expect(pool.connect(User).leave(0)).to.be.revertedWith(
      "lock time is not over"
    );
    await time.increaseTo((await time.latest()) + 86400);
    await pool.connect(User).leave(0);
    const userNewBalance = await DAOToken.balanceOf(User.address);
    expect(userNewBalance).to.equal(parseEther("1000"));
  });
  describe("Admin DAO Reward and User Take the Reward", async function () {
    let admin: SignerWithAddress;
    let pool: DAOStakingPool;
    let DAOToken: AlphaDAO;
    let User: SignerWithAddress;
    before(async () => {
      const [owner, user1] = await ethers.getSigners();
      const Token = await ethers.getContractFactory("AlphaDAO");
      const AlphaDAO = await Token.deploy(owner.address);
      const Level = await ethers.getContractFactory("DAOLevel");
      const DAOLevel = await Level.deploy();
      const Pool = await ethers.getContractFactory("DAOStakingPool");
      pool = (await Pool.deploy(AlphaDAO.address, DAOLevel.address)) as any;
      DAOToken = AlphaDAO as any;
      admin = owner;
      User = user1;
    });
    it("admin reward Token and User take reward", async function () {
      //create pool
      await pool.connect(admin).createPool(DAOToken.address, 86400, 10, false);
      //transfer token
      const tokenNum = parseEther("1000");
      await DAOToken.connect(admin).transfer(User.address, tokenNum);
      //approve token num
      await DAOToken.connect(User).approve(pool.address, tokenNum);
      //deposit token
      await pool.connect(User).deposit(0, tokenNum);
      //admin reward token
      await time.increaseTo((await time.latest()) + 50);
      await DAOToken.connect(admin).approve(pool.address, parseEther("100"));
      const rewardEndTime = (await time.latest()) + 101;
      await pool
        .connect(admin)
        .addBonusToken(DAOToken.address, parseEther("100"), rewardEndTime);
      await time.increaseTo((await time.latest()) + 100);

      //get user pending reward  token num
      const bonusInfo = await pool.bonusToken(DAOToken.address);
      // console.log(bonusInfo)
      const lastrewardTime = bonusInfo.lastRewardTime.toNumber();
      const spacingTime = (await time.latest()) - lastrewardTime;
      // console.log(spacingTime);
      const tokenPerSecond = bonusInfo.tokenPerSecond;
      const totalVeDAO = await pool.getTotalVeDAO();
      // console.log("totalVeDAO: ", totalVeDAO)
      const reward = tokenPerSecond.mul(spacingTime).div(totalVeDAO);
      const acc = bonusInfo.accBonusPerShare.add(parseUnits(reward.toString()));
      const userInfo = await pool.userInfo(0, User.address);
      const bonusNum = userInfo.veDao.mul(acc).div(parseEther("1"));
      // console.log("bonusNum:", bonusNum)
      const pending = await pool.pendingBonus(
        User.address,
        0,
        DAOToken.address
      );
      // console.log("pending:", pending)

      expect(pending).to.equal(bonusNum);

      //user take the reward
      await pool.connect(User).withdrawBonus(0);
      // const newpending = await pool.pendingBonus(User.address, 0, DAOToken.address)
      // console.log("newpending:", newpending)
      const withdrawNum = await DAOToken.balanceOf(User.address);
      // console.log(withdrawNum)
      expect(withdrawNum).to.equal(parseEther("100"));

      //user leave deposit token
      await time.increaseTo((await time.latest()) + 86400);
      await pool.connect(User).leave(0);
      const newBalance = await DAOToken.balanceOf(User.address);
      expect(newBalance).to.equal(parseEther("1100"));
      // const userInfonew = await pool.userInfo(0, User.address);
      // console.log(userInfonew)
    });
  });
});
