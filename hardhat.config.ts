import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import { ethers, ignition } from "hardhat";

const {
  LOCALNETWORK_URL,
  LOCALNETWORKT_DEPLOY_KEY
} = require("./env.json")


const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    warnings: {
      'Ignored.sol': 'off',
      'ethers.js': 'off',
    },
    settings: {
       viaIR: true,
       optimizer: {
         enabled: true,
         runs: 200
       }
     }
  },
  networks:{
    localNetwork: {
      url: LOCALNETWORK_URL,
      chainId: 100,
      accounts: [LOCALNETWORKT_DEPLOY_KEY],
      verify: {
        etherscan: {
          apiUrl: "https://api-testnet.snowtrace.io/",
          apiKey: process.env.SNOWTRACE_API_KEY,
        },
      },
      blockGasLimit: 20_000_000,
      gas: 20_000_000,
    },
  }
};

export default config;
