import { parentPort, workerData } from 'worker_threads';
import { sendTxn, contractAt, getContract, getDeployedContractAddresses } from "../utils/deploy";
import { getLiquidationHealthFactor, getLiquidityAndDebts } from "../utils/helper";
import { MaxUint256 } from "../utils/constants";
import { expandDecimals } from "../utils/math";
import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";
import { LiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";
import { PositionLiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";

(async () => {
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const liquidationHandler = await getDeployedContractAddresses("LiquidationHandler");

    async function liquidation(account){
        const liquidityAndDebts = await getLiquidityAndDebts(dataStore, reader, account);
        for(const l of liquidityAndDebts) {
            if (l.debt > 0) {
                //console.log("liquidityAndDebt", l);
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
        //TODO: should delete approve
        await sendTxn(
            exchangeRouter.executeLiquidation(params),
            "exchangeRouter.executeLiquidation"
        );

    }

    // let url = workerData.url;
    let pokerId = workerData.id;
    console.log("poker: pokerId", pokerId);

    parentPort?.on('message', async (message) => {
        if (message.test) {  
            console.log("test", message.test);
        }

        if (message.accounts) {    
            let accounts = message.accounts;
            for (let i = 0; i < accounts.length; i++){
                //should ordered by healthFactor to poke in priority
                const factor = await getLiquidationHealthFactor(accounts[i]);
                if(!factor.isHealthFactorHigherThanLiquidationThreshold) {
                    await liquidation(accounts[i]);
                    self.postMessage({pokerId:pokerId, liquidated:accounts[i]});
                }           
            }
            self.postMessage({pokerId:pokerId, finished:true});
        } 
    });
})();