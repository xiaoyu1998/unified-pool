import { getContract, sendTxn, getTokens } from "../utils/deploy";
import { bigNumberify, expandDecimals } from "../utils/math";
import { parsePool } from "../utils/helper";

async function main() {
    //create pools
    const usdtDecimals = getTokens("USDT")["decimals"];
    const uniDecimals = getTokens("UNI")["decimals"];
    const usdt = getTokens("USDT")["address"];
    const uni  = getTokens("UNI")["address"];
    const configuration = 0;//TODO:should be assgined to a reasonable configuration
    const poolFactory = await getContract("PoolFactory");
    const poolInterestRateStrategy = await getContract("PoolInterestRateStrategy");
    await sendTxn(
        poolFactory.createPool(usdt, poolInterestRateStrategy.target, configuration),
        "poolFactory.createPool(usdt)"
    );
    await sendTxn(
        poolFactory.createPool(uni, poolInterestRateStrategy.target, configuration),
        "poolFactory.createPool(uni)"
    );

    //set pools configuration
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setHealthFactorLiquidationThreshold", [expandDecimals(110, 25)]),//110%
        config.interface.encodeFunctionData("setDebtMultiplierFactorForRedeem", [expandDecimals(2, 27)]),//2x
        //config.interface.encodeFunctionData("setHealthFactorCollateralRateThreshold", [usdt, expandDecimals(110, 25)]),//110%
        config.interface.encodeFunctionData("setPoolActive", [usdt, true]),
        config.interface.encodeFunctionData("setPoolFreezen", [usdt, false]),
        config.interface.encodeFunctionData("setPoolPaused", [usdt, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [usdt, true]),
        config.interface.encodeFunctionData("setPoolDecimals", [usdt, usdtDecimals]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [usdt, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [usdt, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [usdt, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolUsd", [usdt, true]),
        //config.interface.encodeFunctionData("setHealthFactorCollateralRateThreshold", [uni, expandDecimals(120, 25)]),//120%
        config.interface.encodeFunctionData("setPoolActive", [uni, true]),
        config.interface.encodeFunctionData("setPoolFreezen", [uni, false]),
        config.interface.encodeFunctionData("setPoolPaused", [uni, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [uni, true]),
        config.interface.encodeFunctionData("setPoolDecimals", [uni, uniDecimals]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [uni, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [uni, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [uni, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolUsd", [uni, false]),
    ];
    //const tx = await config.multicall(multicallArgs);
    await sendTxn(
        config.multicall(multicallArgs),
        "config.multicall"
    );

    //print pools
    const dataStore = await getContract("DataStore");    
    const reader = await getContract("Reader");    
    const pools = await reader.getPools(dataStore.target);
    for (const pool of pools) {
        console.log(parsePool(pool));
    }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })