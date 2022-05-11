const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CryptoAdsV1", function () {
  it("Should deploy CryptoAdsV1", async function () {
    const CryptoAdsV1 = await ethers.getContractFactory("CryptoAdsV1");
    const cryptoAdsV1 = await CryptoAdsV1.deploy();
    await cryptoAdsV1.deployed();

    expect(cryptoAdsV1.address).to.not.be.equal(null);
    expect(cryptoAdsV1.address).to.not.be.equal(undefined);
    expect(cryptoAdsV1.address).to.not.be.equal("0x00");
  });
});
