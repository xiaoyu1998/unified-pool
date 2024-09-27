import { contractAt, sendTxn, getContract, getEventEmitter, getDeployedContractAddress } from "../utils/deploy";
import { getLiquidationHealthFactor, getLiquidityAndDebts } from "../utils/helper";
import { MaxUint256 } from "../utils/constants";
import { expandDecimals } from "../utils/math";
// import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";
// import { LiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";
// import { PositionLiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";

import { 
    Mutex,
    readAccounts,
    writeAccounts,
    delAccount,
    addAccount
 } from "../utils/liquidationKeeper";

async function liquidation(account){
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const liquidationHandler = await getDeployedContractAddress("LiquidationHandler");
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
    const [owner] = await ethers.getSigners();
    const eventEmitter = await getEventEmitter();  
    let accounts = readAccounts();
    const mutex = new Mutex();
    eventEmitter.on("Borrow", async (pool, borrower, amount, borrowRate, collateral, debtScaled) => { 
        console.log("eventEmitter Borrow" ,pool, borrower, amount, borrowRate, collateral, debtScaled);
        await addAccount(mutex, accounts, borrower);
    });
    eventEmitter.on("Repay", async (pool, repayer, amount, useCollateral, collateral, debtScaled) => { 
        console.log("eventEmitter Repay", pool, repayer, amount, useCollateral);
        const factor = await getLiquidationHealthFactor(repayer);
        if (factor.userTotalDebtUsd == 0) {
            await delAccount(mutex, accounts, repayer);
        }
    });
    eventEmitter.on("Liquidation", async (liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd) => { 
        console.log("eventEmitter Liquidation", liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd);
        await delAccount(mutex, accounts, account);
    });

    // const config = await getContract("Config");
    // await sendTxn(
    //     config.setHealthFactorLiquidationThreshold(expandDecimals(400, 25)),//400%
    //     "config.setHealthFactorLiquidationThreshold"
    // );

    while(true){
        const accountsChecking = accounts;
        for (const account of accountsChecking) {
            const factor = await getLiquidationHealthFactor(account);
            console.log("factor", factor);
            if(!factor.isHealthFactorHigherThanLiquidationThreshold) {
                await liquidation(account);
            }
        }

        await new Promise(resolve => setTimeout(resolve, 500));
    }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
