import { Worker } from 'worker_threads';
import { getEventEmitter } from "../utils/deploy";
import { getLiquidationHealthFactor } from "../utils/helper";
import { 
    Mutex,
    readAccounts,
    writeAccounts,
    getLiquidatorAccounts,
    delAccount,
    addAccount
 } from "../utils/liquidationKeeper";
 import path from 'path';

async function main() {
    //function 
    const mutex = new Mutex();
    const liquidatorCount = 2;
    let accounts = readAccounts();
    //let liquidators[];

    //listen events
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Borrow", (underlyingAsset, account, amount, borrow) => { 
        await addAccount(mutex, accounts, account);
    });
    eventEmitter.on("Repay", (underlyingAsset, account, repayAmount, useCollateralToRepay) => { 
        const factor = await getLiquidationHealthFactor(account);
        if (factor.userTotalDebtUsd == 0) {
            await delAccount(mutex, accounts, account);
        }
    });
    eventEmitter.on("Liquidation", (liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd) => { 
        await delAccount(mutex, accounts, account);
    });

    //init liquidators
    for (let i = 0; i < liquidatorCount; i++){
        console.log("parent: liquidatorId", i);
        const liquidator = new Worker(path.resolve(__dirname, 'liquidator.ts'), {
            workerData: {id: BigInt(i)}, //should add eth url
            execArgv: ['-r', 'ts-node/register']
        });

        liquidator.postMessage({test: i});
        //console.log("parent: liquidatorId", i);

        //should add eth url
        const accountsLiquidator = getLiquidatorAccounts(accounts, i, liquidatorCount);
        if (accountsLiquidator.length > 0) { liquidator.postMessage({accounts: accountsLiquidator}); }

        liquidator.on('message', (message) => {
            const liquidatorId = message.liquidatorId;
            if (message.liquidated){
                delAccount(accounts, account);
            }
            if (message.finished){
                const accountsLiquidator = getLiquidatorAccounts(accounts, liquidatorId, liquidatorCount);
                if (accountsLiquidator.length > 0) { self.postMessage({accounts: accountsLiquidator}); }
            }
        });
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