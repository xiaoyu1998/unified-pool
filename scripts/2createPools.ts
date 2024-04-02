const { getContract, sendTxn, getTokens } = require("../utils/deploy")
import { bigNumberify, expandDecimals } from "../utils/math";
import { parsePool } from "../utils/helper";


async function main() {
    //create pools
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
        config.interface.encodeFunctionData("setHealthFactorCollateralRateThreshold", [usdt, expandDecimals(110, 25)]),
        config.interface.encodeFunctionData("setPoolActive", [usdt, true]),
        config.interface.encodeFunctionData("setPoolFreeze", [usdt, false]),
        config.interface.encodeFunctionData("setPoolPause", [usdt, false]),
        config.interface.encodeFunctionData("setPoolDecimals", [usdt, 6]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [usdt, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [usdt, expandDecimals(1, 8)]),
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [usdt, expandDecimals(1, 8)]),
        config.interface.encodeFunctionData("setHealthFactorCollateralRateThreshold", [uni, expandDecimals(120, 25)]),
        config.interface.encodeFunctionData("setPoolActive", [uni, true]),
        config.interface.encodeFunctionData("setPoolFreeze", [uni, false]),
        config.interface.encodeFunctionData("setPoolPause", [uni, false]),
        config.interface.encodeFunctionData("setPoolDecimals", [uni, 18]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [uni, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [uni, expandDecimals(1, 8)]),
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [uni, expandDecimals(1, 8)]),
    ];
    const tx = await config.multicall(multicallArgs);

    //print pools
    const dataStore = await getContract("DataStore");    
    const reader = await getContract("Reader");    
    const pools = await reader.getPools(dataStore.target, 0, 10);
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