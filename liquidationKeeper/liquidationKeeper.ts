import { contractAt, getContract, getEventEmitter, getDeployedContractAddresses } from "../utils/deploy";
import { getLiquidationHealthFactor, getLiquidityAndDebts, getPositions } from "../utils/helper";
import { MaxUint256 } from "../utils/constants";
import { expandDecimals } from "../utils/math";
import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";
import { LiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";
import { PositionLiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";


const maxWorkCount = 10;

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

async function main() {

    let workers[];
    for (let i; i < maxWorkCount; i++){
        workers[i] = new Worker('poker')
        workers[i].postMessage({ethUrl: ethUrl[i]});
    }

    const workerMaintainAccounts = new Worker('accountManager')
    workerMaintainAccounts.on('message', (msg) => {
        const accountsMap = splitAccounts(msg.accounts, maxWorkCount);
        for (let i; i < maxWorkCount; i++){
            workers[i].postMessage({accounts: accountsMap[i]});
        }
    })
    //should idle here
}

async function accountManager() {
    //import { parentPort } from 'worker_threads';
    let accounts = readAccounts();
    self.postMessage({accounts:accounts});

    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Borrow", (underlyingAsset, account, amount, borrow) => { 
        const exisiting = addAccount(accounts, account);
        if (!exisiting){
            self.postMessage({accounts:accounts});
            writeAccounts(accounts);
        }
    });

    eventEmitter.on("Repay", (underlyingAsset, account, repayAmount, useCollateralToRepay) => { 
        const factor = await getLiquidationHealthFactor(account);
        if (factor.userTotalDebtUsd == 0) {
            delAccount(accounts, account);
            self.postMessage({accounts:accounts});
            writeAccounts(accounts);
        }
    });

    eventEmitter.on("Liquidation", (liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd) => { 
        delAccount(accounts, account);
        parentPort.postMessage({accounts:accounts});
        writeAccounts(accounts); 
    });

    //should idle here
}

async function poker() {
    //import { parentPort } from 'worker_threads';
    let accounts;

    self.on('message', (message) => {
        //should have a lock
        accounts = message.accounts;
    }

    while(true){
        for (let i; i < accounts.length; i++){
            //should ordered by healthFactor to poke in priority
            const factor = await getLiquidationHealthFactor(accounts[i]);
            if(!factor.isHealthFactorHigherThanLiquidationThreshold) {
                await liquidation(account);
            }           
        }
    }
}



main()
  .then(() => {
    process.exit(0);
  })
  .catch((ex) => {
    console.error(ex);
    process.exit(1);
  });
