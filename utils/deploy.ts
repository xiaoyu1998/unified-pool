import fs from 'fs';
import path from 'path';
import parse from 'csv-parse';

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


const tmpAddressesFilepath = path.join(__dirname, '..', '..', `.tmp-addresses-${process.env.HARDHAT_NETWORK}.json`)

export function readTokenAddresses() {
    if (fs.existsSync(tmpAddressesFilepath)) {
        return JSON.parse(fs.readFileSync(tmpAddressesFilepath))
    }
    return {}
}

export function writeTokenAddresses(json) {
    const tmpAddresses = Object.assign(readTokenAddresses(), json)
    fs.writeFileSync(tmpAddressesFilepath, JSON.stringify(tmpAddresses))
}

export function getTokens(name) {
    const tokens = readTokenAddresses();
    return tokens[name];
}

export async function getContract(name) {

    if (name == "RoleStore" ||
        name == "DataStore" ||
        name == "PoolStoreUtils" ||
        name == "PositionStoreUtils" ||
        name == "FeeUtils" ||
        name == "ConfigStoreUtils" ||     
        name == "OracleStoreUtils"    
    ) {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address);
    }

    const roleStore = getContract("RoleStore");
    const dataStore = getContract("DataStore");
    const poolStoreUtils = getContract("poolStoreUtils");
    const positionStoreUtils = getContract("positionStoreUtils");
    const feeUtils = getContract("FeeUtils");
    const configStoreUtils = getContract("ConfigStoreUtils");
    const oracleStoreUtils = getContract("OracleStoreUtils");

    //Borrow
    // if (name == "BorrowUtils") {
    //     const address = getDeployedContractAddresses(name);
    //     return await contractAtOptions(name, address, {
    //         libraries: {
    //             PoolStoreUtils: poolStoreUtils,
    //             PositionStoreUtils: positionStoreUtils,
    //             FeeUtils: feeUtils,
    //             ConfigStoreUtils: configStoreUtils,
    //             OracleStoreUtils: oracleStoreUtils
    //         },        
    //     });
    // }
    // const borrowUtils = getContract("BorrowUtils");
    // if (name == "BorrowHandler") {
    //      const address = getDeployedContractAddresses(name);
    //     return await contractAtOptions(name, address, [roleStore, dataStore],  {
    //         libraries: {
    //             BorrowUtils: borrowUtils,
    //         },        
    //     });       
    // }


    if (name == "SupplyHandler") {
       const supplyUtilsAddress = getDeployedContractAddresses("SupplyUtils");
       const supplyUtils = await contractAtOptions(name, supplyUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                FeeUtils: feeUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [roleStore, dataStore], {
            libraries: {
                SupplyUtils: supplyUtils,
            },        
        });       
    }

    if (name == "WithdrawHandler") {
       const withdrawUtilsAddress = getDeployedContractAddresses("WithdrawUtils");
       const withdrawUtils = await contractAtOptions(name, withdrawUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                FeeUtils: feeUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [roleStore, dataStore], {
            libraries: {
                WithdrawUtils: withdrawUtils,
            },        
        });       
    }

    if (name == "DepositHandler") {
       const depositUtilsAddress = getDeployedContractAddresses("DepositUtils");
       const depositUtils = await contractAtOptions(name, depositUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [roleStore, dataStore], {
            libraries: {
                DepositUtils: depositUtils,
            },        
        });       
    }

    if (name == "BorrowHandler") {
       const borrowUtilsAddress = getDeployedContractAddresses("BorrowUtils");
       const borrowUtils = await contractAtOptions(name, borrowUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                FeeUtils: feeUtils,
                ConfigStoreUtils: configStoreUtils,
                OracleStoreUtils: oracleStoreUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [roleStore, dataStore],  {
            libraries: {
                BorrowUtils: borrowUtils,
            },        
        });       
    }

    if (name == "RepayHandler") {
       const repayUtilsAddress = getDeployedContractAddresses("RepayUtils");
       const repayUtils = await contractAtOptions(name, repayUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                FeeUtils: feeUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [roleStore, dataStore],  {
            libraries: {
                RepayUtils: repayUtils,
            },        
        });       
    }

    if (name == "RedeemHandler") {
       const redeemUtilsAddress = getDeployedContractAddresses("RedeemUtils");
       const redeemUtils = await contractAtOptions(name, redeemUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                ConfigStoreUtils: configStoreUtils,
                OracleStoreUtils: oracleStoreUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [roleStore, dataStore],  {
            libraries: {
                RedeemUtils: redeemUtils,
            },        
        });       
    }

    const supplyHandler = getContract("SupplyHandler");
    const withdrawHandler = getContract("WithdrawHandler");
    const depositHandler = getContract("DepositHandler");
    const borrowHandler = getContract("BorrowHandler");
    const repayHandler = getContract("RepayHandler");
    const redeemHandler = getContract("RedeemHandler");
    if (name == "ExchangeRouter") {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [
            router,
            roleStore, 
            dataStore,
            supplyHandler,
            withdrawHandler, 
            depositHandler,
            borrowHandler,
            repayHandler, 
            redeemHandler            
        ]);       
    }


    if (name == "Config") {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, [roleStore, dataStore], {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
            },         
        });
    }

    if (name == "Reader") {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils
            },         
        });
    }



}

