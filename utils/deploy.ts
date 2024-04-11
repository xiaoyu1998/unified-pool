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
    let contractFactory;
    if (options){
        contractFactory = await ethers.getContractFactory(name, options);
    } else {
        contractFactory = await ethers.getContractFactory(name);
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

    //console.log(json);
    const tmpAddresses = Object.assign(readTokenAddresses(), json)
    //console.log(tmpAddresses);
    fs.writeFileSync(tmpAddressesFilepath, JSON.stringify(tmpAddresses))
}

export function getTokens(name) {
    const tokens = readTokenAddresses();
    return tokens[name];
}

export async function getEventEmitter() {
    const provider = new ethers.WebSocketProvider("ws://127.0.0.1:8545");
    const address = getDeployedContractAddresses("EventEmitter");
    // let contractFactory = await ethers.getContractFactory("EventEmitter");
    // contractFactory = contractFactory.connect(provider);

    // return await contractFactory.attach(address);

    return contractAtOptions("EventEmitter", address, undefined, provider);

}

export async function getContract(name) {

    if (name == "RoleStore" ||
        name == "DataStore" ||
        name == "PoolStoreUtils" ||
        name == "PositionStoreUtils" ||
        name == "FeeUtils" ||
        name == "ConfigStoreUtils" ||     
        name == "OracleStoreUtils"  ||
        name == "Router" ||
        name == "PoolInterestRateStrategy" ||
        name == "Multicall3" ||
        name == "ReaderUtils" ||
        name == "BorrowEventUtils" ||
        name == "DepositEventUtils" ||
        name == "RedeemEventUtils" ||
        name == "RepayEventUtils" ||
        name == "SupplyEventUtils" ||
        name == "WithdrawEventUtils" ||
        name == "EventEmitter"
    ) {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address);
    }

    const roleStore = await getContract("RoleStore");
    const dataStore = await getContract("DataStore");
    const poolStoreUtils = await getContract("PoolStoreUtils");
    const positionStoreUtils = await getContract("PositionStoreUtils");
//    const feeUtils = await getContract("FeeUtils");
    const configStoreUtils = await getContract("ConfigStoreUtils");
    const oracleStoreUtils = await getContract("OracleStoreUtils");
    const router = await getContract("Router");


    // if (name == "EventEmitter") {
    //     const address = getDeployedContractAddresses(name);
    //     return await contractAtOptions(name, address, {
    //         libraries: {
    //             RoleStore: roleStore,
    //         },         
    //     });
    // }

    if (name == "OracleUtils") {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                OracleStoreUtils: oracleStoreUtils,
            },         
        });
    }

    if (name == "PoolFactory") {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
            },         
        });
    }


    if (name == "Config") {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                OracleStoreUtils: oracleStoreUtils,
            },         
        });
    }

    if (name == "Reader") {
        const oracleUtils = await getContract("OracleUtils");
        // const readerUtils = await getContract("ReaderUtils");
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                // ReaderUtils: readerUtils,
            },         
        });
    }

    if (name == "SupplyHandler") {
        const supplyEventUtils = await getContract("SupplyEventUtils");
        const supplyUtilsAddress = getDeployedContractAddresses("SupplyUtils");
        const supplyUtils = await contractAtOptions("SupplyUtils", supplyUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                SupplyEventUtils: supplyEventUtils,
 //               FeeUtils: feeUtils,
            },        
        });

        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                SupplyUtils: supplyUtils,
            },        
        });       
    }

    if (name == "WithdrawHandler") {
        const withdrawEventUtils = await getContract("WithdrawEventUtils");
        const withdrawUtilsAddress = getDeployedContractAddresses("WithdrawUtils");
        const withdrawUtils = await contractAtOptions("WithdrawUtils", withdrawUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                WithdrawEventUtils: withdrawEventUtils,
 //               FeeUtils: feeUtils,
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
        const depositEventUtils = await getContract("DepositEventUtils");
        const depositUtilsAddress = getDeployedContractAddresses("DepositUtils");
        const depositUtils = await contractAtOptions("DepositUtils", depositUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                DepositEventUtils: depositEventUtils,
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
        const borrowEventUtils = await getContract("BorrowEventUtils");
        const oracleUtils = await getContract("OracleUtils");
        const borrowUtilsAddress = getDeployedContractAddresses("BorrowUtils");
        const borrowUtils = await contractAtOptions("BorrowUtils", borrowUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
//                FeeUtils: feeUtils,
                ConfigStoreUtils: configStoreUtils,
                OracleUtils: oracleUtils,
                BorrowEventUtils: borrowEventUtils,
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
        const repayEventUtils = await getContract("RepayEventUtils");
        const repayUtilsAddress = getDeployedContractAddresses("RepayUtils");
        const repayUtils = await contractAtOptions("RepayUtils", repayUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                RepayEventUtils: repayEventUtils,
//                FeeUtils: feeUtils,
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
        const redeemEventUtils = await getContract("RedeemEventUtils");
        const oracleUtils = await getContract("OracleUtils");
        const redeemUtilsAddress = getDeployedContractAddresses("RedeemUtils");
        const redeemUtils = await contractAtOptions("RedeemUtils", redeemUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                ConfigStoreUtils: configStoreUtils,
                OracleUtils: oracleUtils,
                RedeemEventUtils: redeemEventUtils,
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
        //const router = await getContract("Router");
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

}

export async function getContractAt(name, address) {
    const poolStoreUtils = await getContract("PoolStoreUtils"); 
    if (name == "PoolToken" || name == "DebtToken") {
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
            },         
        });
    } 

    // if (name == "DebtToken") {
    //     return await contractAtOptions(name, address, {
    //         libraries: {
    //             PoolStoreUtils: poolStoreUtils,
    //         },         
    //     });
    // }    
}

