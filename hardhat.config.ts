import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import { ethers, ignition } from "hardhat";
import { defaultRpcs } from "./utils/network";

const getRpcUrl = (network) => {
  let rpc = defaultRpcs[network];
  return rpc;
};

const getEnvAccount = () => {
  const { ACCOUNT_KEY } = process.env;
  if (ACCOUNT_KEY) {
    return [ACCOUNT_KEY];
  }
  return [];
};

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
      url: getRpcUrl("localNetwork"),
      chainId: 10086,
      accounts: getEnvAccount(),
      blockGasLimit: 20_000_000,
      gas: 20_000_000,
    },
  }
};

export default config;
