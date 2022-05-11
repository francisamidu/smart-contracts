async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const CryptoAdsV1 = await ethers.getContractFactory("CryptoAdsV1");
  const cryptoAdsV1 = await CryptoAdsV1.deploy();
  await cryptoAdsV1.deployed();

  console.log("Crpyto AdsV1 address", cryptoAdsV1.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
