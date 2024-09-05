import fs from 'fs';
import path from 'path';
import parse from 'csv-parse';
import { DeployFunction, DeployResult, DeploymentsExtension } from "hardhat-deploy/dist/types";
import {tokenAddresses, deployAddresses, webSocketUrl} from "./network"

export async function logGasUsage(tx, label) {
    const result = await tx;
    const txReceipt = await ethers.provider.getTransactionReceipt(result.hash);
    if (label) {
        console.info(label, txReceipt.gasUsed.toString());
    }
    return txReceipt;
}

export async function sendTxn(txnPromise, label) {
    const txn = await txnPromise
    await txn.wait(1)
    //console.info(`Sent! ${label} ${txn.hash}`)
    return txn
}

export async function deployContractWithCode(abi, code, provider) {
    const contractFactory = new ethers.ContractFactory(abi, code, provider);
    const contract = await contractFactory.deploy();
    await contract.waitForDeployment();
    return contract;
}

export async function contractAtWithCode(abi, code, address, provider) {
    const contractFactory = new ethers.ContractFactory(abi, code, provider);
    const contract = await contractFactory.attach(address);
    return contract;
}

export async function deployContract(name, args, contractOptions = {}) {
    let contractFactory = await ethers.getContractFactory(name, contractOptions);
    let contract = await contractFactory.deploy(...args);
    await contract.waitForDeployment();
    return contract;
}

export async function contractAt(name, address, provider) {
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

export function getDeployedContractAddress(name){
    if (!process.env.HARDHAT_NETWORK){
        process.env.HARDHAT_NETWORK = 'localhost';
    }
    const jsonFile = path.join(__dirname, '..', deployAddresses[`${process.env.HARDHAT_NETWORK}`]);
    const addresses = JSON.parse(fs.readFileSync(jsonFile))
    return addresses[`${name}#${name}`];    
}

export function setDeployedContractAddress(name, address){
    if (!process.env.HARDHAT_NETWORK){
        process.env.HARDHAT_NETWORK = 'localhost';
    }
    const jsonFile = path.join(__dirname, '..', deployAddresses[`${process.env.HARDHAT_NETWORK}`]);
    let addresses = JSON.parse(fs.readFileSync(jsonFile, 'utf8'));
    addresses[`${name}#${name}`] = address;
    fs.writeFileSync(jsonFile, JSON.stringify(addresses, null , 2), 'utf8');     
}

export function readTokenAddresses() {
    if (!process.env.HARDHAT_NETWORK){
        process.env.HARDHAT_NETWORK = 'localhost';
    }
    const assetAddressFile = path.join(__dirname, '..', tokenAddresses[`${process.env.HARDHAT_NETWORK}`]);

    if (fs.existsSync(assetAddressFile)) {
        return JSON.parse(fs.readFileSync(assetAddressFile))
    }
    return {}
}

export function writeTokenAddresses(json) {
    if (!process.env.HARDHAT_NETWORK){
        process.env.HARDHAT_NETWORK = 'localhost';
    }
    const assetAddressFile = path.join(__dirname, '..', tokenAddresses[`${process.env.HARDHAT_NETWORK}`]);

    const assets = Object.assign(readTokenAddresses(), json)
    fs.writeFileSync(assetAddressFile, JSON.stringify(assets, null , 2))
    //console.log(JSON.stringify(assets));
}

export function getTokens(name) {
    const tokens = readTokenAddresses();
    return tokens[name];
}

export async function getEventEmitter() {
    const address = getDeployedContractAddress("EventEmitter");
    const provider = new ethers.WebSocketProvider(webSocketUrl[`${process.env.HARDHAT_NETWORK}`]);
    return contractAtOptions("EventEmitter", address, undefined, provider);
}

export async function getWebSocketContract(name, abi, bytecode, address) {
    const provider = new ethers.WebSocketProvider(webSocketUrl[`${process.env.HARDHAT_NETWORK}`]);
    if (name){
        address = getDeployedContractAddress(name);
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
        name == "CloseEventUtils" ||
        name == "EventEmitter"  || 
        name == "DexStoreUtils" ||
        name == "PoolEventUtils" ||
        name == "FeeStoreUtils" 
    ) {
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address);
    }

    const roleStore = await getContract("RoleStore");
    const dataStore = await getContract("DataStore");
    const poolStoreUtils = await getContract("PoolStoreUtils");
    const positionStoreUtils = await getContract("PositionStoreUtils");
    const poolEventUtils = await getContract("PoolEventUtils");
    const oracleStoreUtils = await getContract("OracleStoreUtils");
    const dexStoreUtils = await getContract("DexStoreUtils");
    const router = await getContract("Router");
    const feeStoreUtils = await getContract("FeeStoreUtils");

    if (name == "FeeHandler") {
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                FeeStoreUtils: feeStoreUtils
            },         
        });
    }

    if (name == "ReaderDexUtils") {
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                DexStoreUtils: dexStoreUtils,
            },         
        });
    }

    if (name == "OracleUtils") {
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                OracleStoreUtils: oracleStoreUtils,
            },         
        });
    }

    const oracleUtils = await getContract("OracleUtils");

    if (name == "ReaderPositionUtils") {
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils
            },         
        });
    }

    if (name == "PoolFactory") {
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                OracleStoreUtils: oracleStoreUtils,
                DexStoreUtils: dexStoreUtils,
            },         
        });
    }

    if (name == "Config") {
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                OracleStoreUtils: oracleStoreUtils,
                DexStoreUtils: dexStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                FeeStoreUtils: feeStoreUtils
            },         
        });
    }

    if (name == "Reader") {
        const readerPositionUtils = await getContract("ReaderPositionUtils");
        const readerDexUtils = await getContract("ReaderDexUtils");
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                ReaderPositionUtils: readerPositionUtils,
                ReaderDexUtils: readerDexUtils,
                PositionStoreUtils: positionStoreUtils,
            },         
        });
    }

    if (name == "RepayUtils") {
        const repayEventUtils = await getContract("RepayEventUtils");
        const address = getDeployedContractAddress("RepayUtils");
        return await contractAtOptions("RepayUtils", address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                RepayEventUtils: repayEventUtils,
                PoolEventUtils: poolEventUtils,
                OracleUtils: oracleUtils,
            },        
        });      
    }

    if (name == "SwapUtils") {
        const swapEventUtils = await getContract("SwapEventUtils");
        //const oracleUtils = await getContract("OracleUtils");
        const address = getDeployedContractAddress("SwapUtils");
        return await contractAtOptions("SwapUtils", address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                DexStoreUtils: dexStoreUtils,
                SwapEventUtils: swapEventUtils,
            },        
        });       
    }

    if (name == "RepaySubstituteUtils") {
        const swapUtils = await getContract("SwapUtils");
        const repayUtils = await getContract("RepayUtils");
        const address = getDeployedContractAddress("RepaySubstituteUtils");
        return await contractAtOptions("RepaySubstituteUtils", address, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                SwapUtils: swapUtils,
                RepayUtils: repayUtils,
            },        
        });       
    }



    if (name == "SupplyHandler") {
        const supplyEventUtils = await getContract("SupplyEventUtils");
        const supplyUtilsAddress = getDeployedContractAddress("SupplyUtils");
        const supplyUtils = await contractAtOptions("SupplyUtils", supplyUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                SupplyEventUtils: supplyEventUtils,
                PoolEventUtils: poolEventUtils,
            },        
        });

        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                SupplyUtils: supplyUtils,
            },        
        });       
    }

    if (name == "WithdrawHandler") {
        const withdrawEventUtils = await getContract("WithdrawEventUtils");
        const withdrawUtilsAddress = getDeployedContractAddress("WithdrawUtils");
        const withdrawUtils = await contractAtOptions("WithdrawUtils", withdrawUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                WithdrawEventUtils: withdrawEventUtils,
                PoolEventUtils: poolEventUtils,
            },        
        });
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                WithdrawUtils: withdrawUtils,
            },        
        });       
    }

    if (name == "DepositHandler") {
        const depositEventUtils = await getContract("DepositEventUtils");
        const depositUtilsAddress = getDeployedContractAddress("DepositUtils");
        const depositUtils = await contractAtOptions("DepositUtils", depositUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                DepositEventUtils: depositEventUtils,
            },        
        });
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address, {
            libraries: {
                DepositUtils: depositUtils,
            },        
        });       
    }

    if (name == "BorrowHandler") {
        const borrowEventUtils = await getContract("BorrowEventUtils");
        const borrowUtilsAddress = getDeployedContractAddress("BorrowUtils");
        const borrowUtils = await contractAtOptions("BorrowUtils", borrowUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                BorrowEventUtils: borrowEventUtils,
                PoolEventUtils: poolEventUtils,
            },        
        });
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                BorrowUtils: borrowUtils,
            },        
        });       
    }

    if (name == "RepayHandler") {
        const repayEventUtils = await getContract("RepayEventUtils");
        const repayUtils = await getContract("RepayUtils");
        const repaySubstituteUtils = await getContract("RepaySubstituteUtils");
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                RepayUtils: repayUtils,
                RepaySubstituteUtils: repaySubstituteUtils,
            },        
        });       
    }

    if (name == "RedeemHandler") {
        const redeemEventUtils = await getContract("RedeemEventUtils");
        const redeemUtilsAddress = getDeployedContractAddress("RedeemUtils");
        const redeemUtils = await contractAtOptions("RedeemUtils", redeemUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                RedeemEventUtils: redeemEventUtils,
            },        
        });
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                RedeemUtils: redeemUtils,
            },        
        });       
    }

    if (name == "SwapHandler") {
        const swapEventUtils = await getContract("SwapEventUtils");
        const swapUtilsAddress = getDeployedContractAddress("SwapUtils");
        const swapUtils = await contractAtOptions("SwapUtils", swapUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                DexStoreUtils: dexStoreUtils,
                SwapEventUtils: swapEventUtils,
            },        
        });
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                SwapUtils: swapUtils,
            },        
        });       
    }

    if (name == "LiquidationHandler") {
        const liquidationEventUtils = await getContract("LiquidationEventUtils");
        const liquidationUtilsAddress = getDeployedContractAddress("LiquidationUtils");
        const liquidationUtils = await contractAtOptions("LiquidationUtils", liquidationUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                OracleUtils: oracleUtils,
                LiquidationEventUtils: liquidationEventUtils,
                PoolEventUtils: poolEventUtils,
            },        
        });
        const address = getDeployedContractAddress(name);
        return await contractAtOptions(name, address,  {
            libraries: {
                LiquidationUtils: liquidationUtils,
            },        
        });       
    }

    if (name == "CloseHandler") {
        const closeEventUtils = await getContract("CloseEventUtils");
        const repayUtils = await getContract("RepayUtils");
        const swapUtils = await getContract("SwapUtils");
        const closeUtilsAddress = getDeployedContractAddress("CloseUtils");
        const closeUtils = await contractAtOptions("CloseUtils", closeUtilsAddress, {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
                PositionStoreUtils: positionStoreUtils,
                RepayUtils: repayUtils,
                SwapUtils: swapUtils,
                OracleUtils: oracleUtils,
                CloseEventUtils: closeEventUtils,
            },        
        });
        const address = getDeployedContractAddress(name);
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
        const address = getDeployedContractAddress(name);
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

