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

//function 
const mutex = new Mutex();
let accounts = readAccounts();
const pokerCount = 10;
let pokers[];

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
for (let i; i < pokerCount; i++){
    pokers[i] = new Worker(path.resolve(__dirname, 'poker.ts'), {
        workerData: {id: BigInt(i)},
        execArgv: ['-r', 'ts-node/register']
    });

    //should add eth url
    pokers[i].postMessage({accounts: getPokerAccounts(accounts, pokerId, pokerCount)});

    pokers[i].on('message', (message) => {
        const pokerId = message.pokerId;
        if (message.liquidated?){
            delAccount(accounts, account);
        }
        if (message.finished?){
            pokers[i].postMessage({accounts: getPokerAccounts(accounts, pokerId, pokerCount)});
        }
    });
}

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