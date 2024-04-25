import { contractAt, getContract, getEventEmitter, getDeployedContractAddresses } from "../utils/deploy";
import { getLiquidationHealthFactor, getLiquidityAndDebts } from "../utils/helper";
import { MaxUint256 } from "../utils/constants";
import { expandDecimals } from "../utils/math";
import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";

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
        console.log("eventEmitter Liquidation" , liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd);
    });
    eventEmitter.on("PositionLiquidation", (underlyingAsset, account, collateral, debt, price) => {
        console.log("eventEmitter PositionLiquidation" , liquidator, underlyingAsset, account, collateral, debt, price);
    });

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
