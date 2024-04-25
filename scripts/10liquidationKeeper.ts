import { contractAt, getContract, getEventEmitter, getDeployedContractAddresses } from "../utils/deploy";
import { getLiquidationHealthFactor, getLiquidityAndDebts, getPositions } from "../utils/helper";
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
    // const dataStore = await getContract("DataStore");   
    // const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Liquidation", (liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd) => { 
        const event: LiquidationEvent.OutputTuple = {
            liquidator: liquidator,
            account: account,
            healthFactor: healthFactor,
            healthFactorLiquidationThreshold: healthFactorLiquidationThreshold,
            totalCollateralUsd: totalCollateralUsd,
            totalDebtUsd: totalDebtUsd
        };
        console.log("eventEmitter Liquidation" , event);
    });
    eventEmitter.on("PositionLiquidation", (liquidator, underlyingAsset, account, collateral, debt, price) => {
        const event: PositionLiquidationEvent.OutputTuple = {
            liquidator: liquidator,
            underlyingAsset: underlyingAsset,
            account: account,
            collateral: collateral,
            debt: debt,
            price: price
        };
        console.log("eventEmitter PositionLiquidation", event);
    });

    const config = await getContract("Config");
    await config.setHealthFactorLiquidationThreshold(expandDecimals(400, 25))//400%

    while(true){
        const account = owner.address;
        // const position = await getPositions(dataStore, reader, account);
        // console.log("position", position);
        const factor = await getLiquidationHealthFactor(account);
        console.log("factor", factor);
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
