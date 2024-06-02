import { parentPort } from 'worker_threads, workerData';
import { contractAt, getContract, getEventEmitter, getDeployedContractAddresses } from "../utils/deploy";
import { getLiquidationHealthFactor, getLiquidityAndDebts, getPositions } from "../utils/helper";
import { MaxUint256 } from "../utils/constants";
import { expandDecimals } from "../utils/math";
import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";
import { LiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";
import { PositionLiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";

async function liquidation(account){
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const liquidationHandler = await getDeployedContractAddresses("LiquidationHandler");
    const liquidityAndDebts = await getLiquidityAndDebts(dataStore, reader, account);
    for(const l of liquidityAndDebts) {
        if (l.debt > 0) {
            console.log("liquidityAndDebt", l);
            const underlyingAsset = await contractAt("MintableToken", l.underlyingAsset); 
            //await underlyingAsset.approve(liquidationHandler, MaxUint256);//allowance should be deleted after liquidation
            await sendTxn(
                underlyingAsset.approve(liquidationHandler, MaxUint256),
                "underlyingAsset.approve"
            );
        }
    }

    const params: LiquidationUtils.LiquidationParamsStruct = {
        account: account
    };
    //await exchangeRouter.executeLiquidation(params);
    await sendTxn(
        exchangeRouter.executeLiquidation(params),
        "exchangeRouter.executeLiquidation"
    );

}


let pokerId = workerData.id;
// let url = workerData.url;
parentPort?.on('message', (message) => {
    let accounts = message.accounts;
    for (let i; i < accounts.length; i++){
        //should ordered by healthFactor to poke in priority
        const factor = await getLiquidationHealthFactor(accounts[i]);
        if(!factor.isHealthFactorHigherThanLiquidationThreshold) {
            await liquidation(account);
            parentPort?.postMessage({pokerId:pokerId, liquidated:accounts[i]});
        }           
    }
    parentPort?.postMessage({pokerId:pokerId, finished:true});
});