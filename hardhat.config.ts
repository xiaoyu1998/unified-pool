import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import { ethers, ignition } from "hardhat";

const getRpcUrl = (network) => {
  const defaultRpcs = {
    localNetwork: "http://192.168.2.106:8545",
  };

  let rpc = defaultRpcs[network];
  return rpc;
};

const getEnvAccount = () => {
  const { ACCOUNT_KEY } = process.env;
  return [ACCOUNT_KEY];
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
