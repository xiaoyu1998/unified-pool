import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import "@nomicfoundation/hardhat-foundry";
import { ethers, ignition } from "hardhat";
import { defaultRpcs } from "./utils/network";

const getRpcUrl = (network) => {
    let rpc = defaultRpcs[network];
    return rpc;
};

const getEnvAccount = () => {
    const { ACCOUNT_KEY } = process.env;
    if (ACCOUNT_KEY) {
        //return [ACCOUNT_KEY];
        return ACCOUNT_KEY.split(",");
    }
    return [];
};

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.20",
        settings: {
             optimizer: {
                 enabled: true,
                 runs: 200
             }
         }
    },
    networks:{
        localnet: {
            url: getRpcUrl("localnet"),
            chainId: 1998,
            accounts: getEnvAccount(),
            blockGasLimit: 20_000_000,
            gas: 20_000_000,
        },
        testnet: {
            url: getRpcUrl("testnet"),
            chainId: 31337,
            accounts: getEnvAccount(),
            blockGasLimit: 20_000_000,
            gas: 20_000_000,
        },
    }
};

export default config;
