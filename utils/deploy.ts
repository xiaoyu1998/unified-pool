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

    console.log(json);
    const tmpAddresses = Object.assign(readTokenAddresses(), json)
    console.log(tmpAddresses);
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
        name == "OracleStoreUtils"  ||
        name == "Router"
    ) {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address);
    }

    const roleStore = await getContract("RoleStore");
    const dataStore = await getContract("DataStore");
    const poolStoreUtils = await getContract("PoolStoreUtils");
    const positionStoreUtils = await getContract("PositionStoreUtils");
    const feeUtils = await getContract("FeeUtils");
    const configStoreUtils = await getContract("ConfigStoreUtils");
    const oracleStoreUtils = await getContract("OracleStoreUtils");
    const router = await getContract("Router");

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
    //     return await contractAtOptions(name, address,  {
    //         libraries: {
    //             BorrowUtils: borrowUtils,
    //         },        
    //     });       
    // }


    if (name == "SupplyHandler") {
       const supplyUtilsAddress = getDeployedContractAddresses("SupplyUtils");
       const supplyUtils = await contractAtOptions("SupplyUtils", supplyUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                FeeUtils: feeUtils,
            },        
        });

        console.log(supplyUtils);
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                SupplyUtils: supplyUtils,
            },        
        });       
    }

    if (name == "WithdrawHandler") {
       const withdrawUtilsAddress = getDeployedContractAddresses("WithdrawUtils");
       const withdrawUtils = await contractAtOptions("WithdrawUtils", withdrawUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                FeeUtils: feeUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                WithdrawUtils: withdrawUtils,
            },        
        });       
    }

    if (name == "DepositHandler") {
       const depositUtilsAddress = getDeployedContractAddresses("DepositUtils");
       const depositUtils = await contractAtOptions("DepositUtils", depositUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                DepositUtils: depositUtils,
            },        
        });       
    }

    if (name == "BorrowHandler") {
       const borrowUtilsAddress = getDeployedContractAddresses("BorrowUtils");
       const borrowUtils = await contractAtOptions("BorrowUtils", borrowUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                FeeUtils: feeUtils,
                ConfigStoreUtils: configStoreUtils,
                OracleStoreUtils: oracleStoreUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                BorrowUtils: borrowUtils,
            },        
        });       
    }

    if (name == "RepayHandler") {
       const repayUtilsAddress = getDeployedContractAddresses("RepayUtils");
       const repayUtils = await contractAtOptions("RepayUtils", repayUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                FeeUtils: feeUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                RepayUtils: repayUtils,
            },        
        });       
    }

    if (name == "RedeemHandler") {
       const redeemUtilsAddress = getDeployedContractAddresses("RedeemUtils");
       const redeemUtils = await contractAtOptions("RedeemUtils", redeemUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                ConfigStoreUtils: configStoreUtils,
                OracleStoreUtils: oracleStoreUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                RedeemUtils: redeemUtils,
            },        
        });       
    }

    if (name == "ExchangeRouter") {
        const supplyHandler = await getContract("SupplyHandler");
        const withdrawHandler = await getContract("WithdrawHandler");
        const depositHandler = await getContract("DepositHandler");
        const borrowHandler = await getContract("BorrowHandler");
        const repayHandler = await getContract("RepayHandler");
        const redeemHandler = await getContract("RedeemHandler");
        const router = await getContract("Router");
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
        return await contractAtOptions(name, address, {
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

