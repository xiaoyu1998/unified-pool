const { getContract, sendTxn, getTokens } = require("../utils/deploy")
import { expandDecimals } from "../utils/math";
import { parsePool } from "../utils/helper";

async function main() {
    const [owner] = await ethers.getSigners();

    // const tokens = readTmpAddresses();
    // console.log("tokens", tokens);
    const usdt = getTokens("usdt");
    const uni  = getTokens("uni");
    const configuration = 1;//TODO:should be assgined to a reasonable value
    const poolFactory = await getContract("PoolFactory");
    const strategy = await getContract("PoolInterestRateStrategy");

    await sendTxn(
        poolFactory.createPool(usdt, strategy.target, configuration),
        "poolFactory.createPool(usdt)"
    );
    await sendTxn(
        poolFactory.createPool(uni, strategy.target, configuration),
        "poolFactory.createPool(uni)"
    );

    const config = await getContract("Config");
    //usdt
    await sendTxn(
        config.setPoolActive(usdt, true),
        "config.setPoolActive(usdt, true)"
    );

    await sendTxn(
        config.setPoolFreeze(usdt, false),
        "config.setPoolFreeze(usdt, true)"
    );
    await sendTxn(
        config.setPoolPause(usdt, false),
        "config.setPoolFreeze(usdt, true)"
    );
    await sendTxn(
        config.setPoolDecimals(usdt, 6),
        "config.setPoolDecimals(usdt, 27)"
    );
    await sendTxn(
        config.setPoolFeeFactor(usdt, 10), //1/1000
        "config.setPoolFeeFactor(usdt, 10)"
    );
    await sendTxn(
        config.setPoolBorrowCapacity(usdt, expandDecimals(1, 8)), 
        "config.setPoolBorrowCapacity(usdt, 10)"
    );
    await sendTxn(
        config.setPoolSupplyCapacity(usdt, expandDecimals(1, 8)), 
        "config.setPoolSupplyCapacity(usdt, 10)"
    );

    //uni
     await sendTxn(
        config.setPoolActive(uni, true),
        "config.setPoolActive(uni, true)"
    );

    await sendTxn(
        config.setPoolFreeze(uni, false),
        "config.setPoolFreeze(uni, true)"
    );
    await sendTxn(
        config.setPoolPause(uni, false),
        "config.setPoolFreeze(uni, true)"
    );
    await sendTxn(
        config.setPoolDecimals(uni, 18),
        "config.setPoolDecimals(uni, 27)"
    );
    await sendTxn(
        config.setPoolFeeFactor(uni, 10), //1/1000
        "config.setPoolFeeFactor(uni, 10)"
    );
    await sendTxn(
        config.setPoolBorrowCapacity(uni, expandDecimals(1, 8)), 
        "config.setPoolBorrowCapacity(uni, 10)"
    );
    await sendTxn(
        config.setPoolSupplyCapacity(uni, expandDecimals(1, 8)), 
        "config.setPoolSupplyCapacity(uni, 10)"
    );     

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