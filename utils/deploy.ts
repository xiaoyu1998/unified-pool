import { DeployFunction, DeployResult, DeploymentsExtension } from "hardhat-deploy/dist/types";
import deployed_address from "../ignition/deployments/chain-31337/deployed_addresses.json";

export async function sendTxn(txnPromise, label) {
    console.info(`Processsing ${label}:`)
    const txn = await txnPromise
    console.info(`Sending ${label}...`)
    await txn.wait(1)
    console.info(`... Sent! ${txn.hash}`)
    return txn
}

export async function deployContract(name, args, contractOptions = {}) {
    const contractFactory = await ethers.getContractFactory(name, contractOptions);
    return await contractFactory.deploy(...args);
}

export async function contractAt(name, address, options, provider) {
    let contractFactory = await ethers.getContractFactory(name);
    if (provider) {
        contractFactory = contractFactory.connect(provider);
    }
    return await contractFactory.attach(address);
}

export async function contractAtOptions(name, address, options, provider) {
    let contractFactory
    if (options){
        contractFactory = await ethers.getContractFactory(name, options)
    } else {
        contractFactory = await ethers.getContractFactory(name)
    }
    
    if (provider) {
        contractFactory = contractFactory.connect(provider);
    }
    return await contractFactory.attach(address);
}

export function getDeployedContractAddresses(name){
    return deployed_address[`${name}#${name}`];
}