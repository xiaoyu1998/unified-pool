import { Worker } from 'worker_threads';
import { getEventEmitter } from "../utils/deploy";
import { getLiquidationHealthFactor } from "../utils/helper";
import { 
    Mutex,
    readAccounts,
    writeAccounts,
    getPokerAccounts
 } from "../utils/liquidationKeeper";
 import path from 'path';

async function main() {
    //function 
    const mutex = new Mutex();
    const pokerCount = 2;
    let accounts = readAccounts();
    //let pokers[];

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

    //init pokers
    for (let i = 0; i < pokerCount; i++){
        console.log("parent: pokerId", i);
        const poker = new Worker(path.resolve(__dirname, 'poker.ts'), {
            workerData: {id: BigInt(i)}, //should add eth url
            execArgv: ['-r', 'ts-node/register']
        });

        poker.postMessage({test: i});
        //console.log("parent: pokerId", i);

        //should add eth url
        const accountsPoker = getPokerAccounts(accounts, i, pokerCount);
        if (accountsPoker.length > 0) { poker.postMessage({accounts: accountsPoker}); }

        poker.on('message', (message) => {
            const pokerId = message.pokerId;
            if (message.liquidated){
                delAccount(accounts, account);
            }
            if (message.finished){
                const accountsPoker = getPokerAccounts(accounts, pokerId, pokerCount);
                if (accountsPoker.length > 0) { self.postMessage({accounts: accountsPoker}); }
            }
        });
    }

}

main();

async function delAccount(mutex, accounts, account) {
    await mutex.dispatch(async () => {
        accounts = accounts.filter(item => item !== account)
        writeAccounts(accounts);
    });
}

async function addAccount(mutex, accounts, account) {
    await mutex.dispatch(async () => {
        if (accounts.indexOf(account) == -1) {
            accounts.push(account);
            writeAccounts(accounts);
        }
    });
}