
require('dotenv').config();

const mnemonic = process.env.MNEMONIC;
const api_key = process.env.ALCHEMY_API_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 module.exports = {

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${api_key}`,
        blockNumber:  12778818,
        enabled: true,
    },
    },
    rinkeby: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${api_key}`,
      accounts: { mnemonic, },
    },
    kovan: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${api_key}`,
      accounts: { mnemonic, },
    }
},
  solidity: {
    compilers: [
        {
            version: "0.6.12",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
            },
        },
        {
            version: "0.8.0",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
            },
        },
    ],
},
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
}
