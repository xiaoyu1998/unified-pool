import { contractAt, getContract, getEventEmitter, getDeployedContractAddresses } from "../utils/deploy";
import { getLiquidationHealthFactor, getLiquidityAndDebts } from "../utils/helper";
import { MaxUint256 } from "../utils/constants";
import { expandDecimals } from "../utils/math";
import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";
import { LiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";
import { PositionLiquidationEvent } from "../typechain-types/contracts/event/EventEmitter";

async function liquidation(account){
    const [owner] = await ethers.getSigners();

    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const liquidationHandler = await getDeployedContractAddresses("LiquidationHandler");

    const liquidityAndDebts = await getLiquidityAndDebts(dataStore, reader, account);
    //console.log("liquidityAndDebts", liquidityAndDebts);
    for(const l of liquidityAndDebts) {
        if (l.debt > 0) {
            console.log("liquidityAndDebt", l);
            const underlyingAsset = await contractAt("MintableToken", l.underlyingAsset); 
            await underlyingAsset.approve(liquidationHandler, MaxUint256);//allowance should be deleted after liquidation
        }
    }

    const params: LiquidationUtils.LiquidationParamsStruct = {
        account: account
    };
    await exchangeRouter.executeLiquidation(params);

}

async function main() {
    const [owner] = await ethers.getSigners();

    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Liquidation", (liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd) => { 
        const e: LiquidationEvent.OutputTuple = {
            liquidator: liquidator,
            account: account,
            healthFactor: healthFactor,
            healthFactorLiquidationThreshold: healthFactorLiquidationThreshold,
            totalCollateralUsd: totalCollateralUsd,
            totalDebtUsd: totalDebtUsd
        };
        console.log("eventEmitter Liquidation" , e);
    });
    eventEmitter.on("PositionLiquidation", (underlyingAsset, account, collateral, debt, price) => {
        const e: PositionLiquidationEvent.OutputTuple = {
            liquidator: liquidator,
            underlyingAsset: underlyingAsset,
            account: account,
            collateral: collateral,
            debt: debt,
            price: price
        };
        console.log("eventEmitter PositionLiquidation", e);
    });

    // eventEmitter.on("Liquidation", (liquidation) => { 
    //     console.log("eventEmitter Liquidation", liquidation);
    // });
    // eventEmitter.on("PositionLiquidation", (positionLiquidation) => {
    //     console.log("eventEmitter PositionLiquidation", positionLiquidation);
    // });

    const config = await getContract("Config");
    await config.setHealthFactorLiquidationThreshold(expandDecimals(400, 25))//400%

    while(true){
        const account = owner.address;
        const factor = await getLiquidationHealthFactor(account);
        //console.log("factor", factor);
        if(!factor.isHealthFactorHigherThanLiquidationThreshold) {
            await liquidation(account);
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
