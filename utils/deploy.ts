import fs from 'fs';
import path from 'path';
import parse from 'csv-parse';

import { DeployFunction, DeployResult, DeploymentsExtension } from "hardhat-deploy/dist/types";
import deployed_address from "../ignition/deployments/chain-31337/deployed_addresses.json";
import { WS_URL } from "./constants"

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
    const address = getDeployedContractAddresses("EventEmitter");
    const provider = new ethers.WebSocketProvider(WS_URL);
    return contractAtOptions("EventEmitter", address, undefined, provider);
    // return getWebSocketContract("EventEmitter", address)
}

export async function getWebSocketContract(name, abi, bytecode, address) {
    const provider = new ethers.WebSocketProvider(WS_URL);
    if (name){
        address = getDeployedContractAddresses(name);
        return contractAtOptions(name, address, undefined, provider);       
    }

    let contractFactory = new ethers.ContractFactory(abi, bytecode);
    contractFactory = contractFactory.connect(provider);
    return await contractFactory.attach(address);
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
        name == "BorrowEventUtils" ||
        name == "DepositEventUtils" ||
        name == "RedeemEventUtils" ||
        name == "RepayEventUtils" ||
        name == "SupplyEventUtils" ||
        name == "WithdrawEventUtils" ||
        name == "SwapEventUtils" ||
        name == "LiquidationEventUtils" ||
        name == "EventEmitter"  || 
        name == "DexStoreUtils" 
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
    const dexStoreUtils = await getContract("DexStoreUtils");
    const router = await getContract("Router");

    if (name == "OracleUtils") {
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                OracleStoreUtils: oracleStoreUtils,
            },         
        });
    }

    if (name == "ReaderUtils") {
        const oracleUtils = await getContract("OracleUtils");
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                ConfigStoreUtils: configStoreUtils,
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
                DexStoreUtils: dexStoreUtils
            },         
        });
    }

    if (name == "Reader") {
        const oracleUtils = await getContract("OracleUtils");
        const readerUtils = await getContract("ReaderUtils");
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                ConfigStoreUtils: configStoreUtils,
                ReaderUtils: readerUtils,
            },         
        });
    }

    if (name == "RepayUtils") {
        const repayEventUtils = await getContract("RepayEventUtils");
        const repayUtilsAddress = getDeployedContractAddresses("RepayUtils");
        return await contractAtOptions("RepayUtils", repayUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                RepayEventUtils: repayEventUtils,
//                FeeUtils: feeUtils,
            },        
        });      
    }

    if (name == "SwapUtils") {
        const swapEventUtils = await getContract("SwapEventUtils");
        const oracleUtils = await getContract("OracleUtils");
        const swapUtilsAddress = getDeployedContractAddresses("SwapUtils");
        return await contractAtOptions("SwapUtils", swapUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
               // ConfigStoreUtils: configStoreUtils,
                OracleUtils: oracleUtils,
                DexStoreUtils: dexStoreUtils,
                SwapEventUtils: swapEventUtils,
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
        const oracleUtils = await getContract("OracleUtils");
        const depositUtilsAddress = getDeployedContractAddresses("DepositUtils");
        const depositUtils = await contractAtOptions("DepositUtils", depositUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
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

    if (name == "SwapHandler") {
        const swapEventUtils = await getContract("SwapEventUtils");
        const oracleUtils = await getContract("OracleUtils");
        const swapUtilsAddress = getDeployedContractAddresses("SwapUtils");
        const swapUtils = await contractAtOptions("SwapUtils", swapUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
               // ConfigStoreUtils: configStoreUtils,
                OracleUtils: oracleUtils,
                DexStoreUtils: dexStoreUtils,
                SwapEventUtils: swapEventUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                SwapUtils: swapUtils,
            },        
        });       
    }

    if (name == "LiquidationHandler") {
        const liquidationEventUtils = await getContract("LiquidationEventUtils");
        const oracleUtils = await getContract("OracleUtils");
        const liquidationUtilsAddress = getDeployedContractAddresses("LiquidationUtils");
        const liquidationUtils = await contractAtOptions("LiquidationUtils", liquidationUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                ConfigStoreUtils: configStoreUtils,
                OracleUtils: oracleUtils,
                LiquidationEventUtils: liquidationEventUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                LiquidationUtils: liquidationUtils,
            },        
        });       
    }

    if (name == "CloseHandler") {
        //const closeEventUtils = await getContract("CloseEventUtils");
        const repayUtils = await getContract("RepayUtils");
        const swapUtils = await getContract("SwapUtils");
        const closeUtilsAddress = getDeployedContractAddresses("CloseUtils");
        const closeUtils = await contractAtOptions("CloseUtils", closeUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                RepayUtils: repayUtils,
                SwapUtils: swapUtils,
                DexStoreUtils: dexStoreUtils,
                //CloseEventUtils: closeEventUtils,
            },        
        });
        const address = getDeployedContractAddresses(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                CloseUtils: closeUtils,
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
        const swapHandler = await getContract("SwapHandler");
        const liquidationHandler = await getContract("LiquidationHandler");
        const closeHandler = await getContract("CloseHandler");
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
            redeemHandler,  
            swapHandler, 
            liquidationHandler, 
            closeHandler      
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
}

