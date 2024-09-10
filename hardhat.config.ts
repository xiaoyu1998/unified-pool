import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-contract-sizer";
import { ethers, ignition } from "hardhat";
import { defaultRpcs } from "./utils/network";

const getRpcUrl = (network) => {
    if (network == "sepolia") {
        const { urlSepolia } = process.env;
        if (urlSepolia) {
            return urlSepolia;
        }
    }
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
         },
        contractSizer: {
            runOnCompile: true,      // Runs the sizer after each compilation
            disambiguatePaths: false, // Optional: Disambiguates contracts with the same name
        },
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
            chainId: 1998,
            accounts: getEnvAccount(),
            blockGasLimit: 20_000_000,
            gas: 20_000_000,
        },
        sepolia: {
            url: getRpcUrl("sepolia"),
            chainId: 11155111,
            accounts: getEnvAccount(),
            blockGasLimit: 20_000_000,
            gas: 20_000_000,
        },
    }
};

export default config;
