const { getContract, sendTxn, getTokens } = require("../utils/deploy")
import { expandDecimals } from "../utils/math";
import { parsePool } from "../utils/helper";


async function main() {
    const [owner] = await ethers.getSigners();

    const usdt = getTokens("usdt");
    const uni  = getTokens("uni");
    const configuration = 1;//TODO:should be assgined to a reasonable value
    const poolFactory = await getContract("PoolFactory");
    const strategy = await getContract("PoolInterestRateStrategy");

     //create pools
    await sendTxn(
        poolFactory.createPool(usdt, strategy.target, configuration),
        "poolFactory.createPool(usdt)"
    );
    await sendTxn(
        poolFactory.createPool(uni, strategy.target, configuration),
        "poolFactory.createPool(uni)"
    );

    //set pool configuration
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setPoolActive", [usdt, true]),
        config.interface.encodeFunctionData("setPoolFreeze", [usdt, false]),
        config.interface.encodeFunctionData("setPoolPause", [usdt, false]),
        config.interface.encodeFunctionData("setPoolDecimals", [usdt, 6]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [usdt, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [usdt, expandDecimals(1, 8)]),
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [usdt, expandDecimals(1, 8)]),
        config.interface.encodeFunctionData("setPoolActive", [uni, true]),
        config.interface.encodeFunctionData("setPoolFreeze", [uni, false]),
        config.interface.encodeFunctionData("setPoolPause", [uni, false]),
        config.interface.encodeFunctionData("setPoolDecimals", [uni, 18]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [uni, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [uni, expandDecimals(1, 8)]),
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [uni, expandDecimals(1, 8)]),
    ];
    const multicall = await getContract("Multicall3");
    const tx = await multicall.aggregate(multicallArgs);
    //const exchangeRouter = await getContract("ExchangeRouter"); 
    //const tx = await exchangeRouter.multicall(multicallArgs);  

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