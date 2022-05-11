require("@nomiclabs/hardhat-waffle");

require("@nomiclabs/hardhat-waffle");
const mnemonic =
  "wasp pipe mosquito wolf power solid idle mimic library beef print tail";

module.exports = {
  solidity: "0.8.4",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com/v1/ee4bb44018173adcac750ef9ae9b933f5419a17e",
      accounts: {
        mnemonic,
      },
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: {
        mnemonic,
      },
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: { mnemonic },
    },
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
