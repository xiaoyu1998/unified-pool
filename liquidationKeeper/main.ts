import { Worker } from 'worker_threads';
import { getEventEmitter } from "../utils/deploy";
import { getLiquidationHealthFactor } from "../utils/helper";
import { 
    delAccount,
    addAccount,
    Mutex,
    readAccounts,
    writeAccounts,
    getPokerAccounts
 } from "./helper";
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
        await addAccount(accounts, account);
    });
    eventEmitter.on("Repay", (underlyingAsset, account, repayAmount, useCollateralToRepay) => { 
        const factor = await getLiquidationHealthFactor(account);
        if (factor.userTotalDebtUsd == 0) {
            await delAccount(accounts, account);
        }
    });
    eventEmitter.on("Liquidation", (liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd) => { 
        await delAccount(accounts, account);
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

export async function delAccount(account) {
    await mutex.dispatch(async () => {
        accounts = accounts.filter(item => item !== account)
        writeAccounts(accounts);
    });
}

export async function addAccount(account) {
    await mutex.dispatch(async () => {
        accounts.push(account);
        writeAccounts(accounts);
    });
}