import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
// import { ethers } from "ethers";
// import "@nomicfoundation/hardhat-ethers";
import { ethers, ignition } from "hardhat";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
       optimizer: {
         enabled: true,
         runs: 200
       }
     }
  }
};

export default config;
