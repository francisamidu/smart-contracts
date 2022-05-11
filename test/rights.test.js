const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Rights", () => {
  let rights = null;
  let rightsMarket = null;
  let rightPrice = ethers.utils.parseEther("0.5");
  before("Deploys contracts successfully", async () => {
    rightsMarket = await ethers.getContractFactory("RightsMarket");
    rightsMarket = await rightsMarket.deploy();
    await rightsMarket.deployed();

    rights = await ethers.getContractFactory("NFT");
    rights = await rights.deploy(
      "Rights",
      "RGHTS",
      rightsMarket.address,
      "http://localhost:8080/ipfs/QmWPb1AkXiy3po4dCPMvLEJ9J1Dc8gtkR482gKFKmndVhe/"
    );

    await rights.deployed();

    expect(rights.address).to.not.be.equal(null);
    expect(rights.address).to.not.be.equal(undefined);
    expect(rights.address).to.not.be.equal("0x00");

    expect(rightsMarket.address).to.not.be.equal(null);
    expect(rightsMarket.address).to.not.be.equal(undefined);
    expect(rightsMarket.address).to.not.be.equal("0x00");
  });
  it("Mints a token", async () => {
    const transaction1 = await rights.mint();
    const transaction2 = await rights.mint();
    const tx1 = await transaction1.wait();
    const tx2 = await transaction2.wait();
    const tokenId1 = tx1.events[0].args.tokenId.toString();
    const tokenId2 = tx2.events[0].args.tokenId.toString();

    await rightsMarket.listRight(
      tokenId1,
      rights.address,
      rightPrice,
      "Printing",
      Date.now()
    );

    await rightsMarket.listRight(
      tokenId2,
      rights.address,
      rightPrice,
      "Cooking",
      Date.now()
    );
  });
  it("Retrieves all the rights", async () => {
    let tokenIds = (await rights._tokenId()).toString();
    const tokens = [];
    for (let id = 1; id <= tokenIds; id++) {
      let token = await rightsMarket.idToRight(id);
      const tokenUri = await rights.tokenURI(id);
      token = {
        token: Number(token.tokenId.toString()),
        price: Number(token.price.toString()),
        usage: token.usage,
        tokenUri,
      };
      tokens.push(token);
    }
    console.log(tokens);
  });
  it("Purchase a right", async () => {
    const { 1: buyer } = await ethers.getSigners();
    await rightsMarket.connect(buyer).purchaseRight(1, rights.address, {
      value: rightPrice,
    });
  });
  it("Check wallet balance", async () => {
    const { 1: buyer } = await ethers.getSigners();
    let walletOfOwner = await rights.walletOfOwner(buyer.address);
    walletOfOwner = walletOfOwner.map((item) => Number(item.toString()));
    console.log("Wallet of owner:", walletOfOwner);
  });
  it("Check Market balance", async () => {
    const balance = (
      await ethers.provider.getBalance(rightsMarket.address)
    ).toString();
    console.log("Market balance:", balance);
  });
  it("Withdraws market balance", async () => {
    await rightsMarket.withdraw();
  });
  it("Check Market balance and deployer", async () => {
    const [signer] = await ethers.getSigners();
    const marketBalance = (
      await ethers.provider.getBalance(rightsMarket.address)
    ).toString();
    console.log("Market balance:", marketBalance);

    const deployerBalance = (
      await ethers.provider.getBalance(signer.address)
    ).toString();
    console.log("Deployer balance:", deployerBalance);
  });
});
