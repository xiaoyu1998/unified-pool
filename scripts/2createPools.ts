const { contractAtOptions, sendTxn, getDeployedContractAddresses } = require("../utils/deploy")
import { hashString } from "../utils/hash";

async function main() {
    const [owner] = await ethers.getSigners();

    const poolStoreUtilsAddress = getDeployedContractAddresses("PoolStoreUtils");
    const roleStoreAddress = getDeployedContractAddresses("RoleStore");
    const dataStoreAddress = getDeployedContractAddresses("DataStore");
    const configAddress = getDeployedContractAddresses("Config");
    const poolFactoryAddress = getDeployedContractAddresses("PoolFactory");
    const positionStoreUtilsAddress = getDeployedContractAddresses("PositionStoreUtils");
    const strategyAddress = getDeployedContractAddresses("PoolInterestRateStrategy");
    const readerAddress = getDeployedContractAddresses("Reader");

    const usdt = "0xc9a43158891282a2b1475592d5719c001986aaec";
    const uni  = "0x1c85638e118b37167e9298c2268758e058ddfda0";
    const configuration = 1;
    
    const poolStoreUtils = await contractAtOptions("PoolStoreUtils", poolStoreUtilsAddress);
    const poolFactory = await contractAtOptions("PoolFactory", poolFactoryAddress,{
        libraries: {
            PoolStoreUtils: poolStoreUtils
        },
    });

    await sendTxn(
        poolFactory.createPool(usdt, strategyAddress, configuration),
        "poolFactory.createPool(usdt)"
    );
    await sendTxn(
        poolFactory.createPool(uni, strategyAddress, configuration),
        "poolFactory.createPool(uni)"
    );


    //console.log(poolFactory.target);
    const config = await contractAtOptions("Config", configAddress,{
        libraries: {
            PoolStoreUtils: poolStoreUtils
        },
    });
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
        config.setPoolDecimals(usdt, 27),
        "config.setPoolDecimals(usdt, 27)"
    );
    await sendTxn(
        config.setPoolFeeFactor(usdt, 10), //1/10000
        "config.setPoolFeeFactor(usdt, 10)"
    );
    await sendTxn(
        config.setPoolBorrowCapacity(usdt, 10**10), 
        "config.setPoolBorrowCapacity(usdt, 10)"
    );
    await sendTxn(
        config.setPoolSupplyCapacity(usdt, 10**10), 
        "config.setPoolSupplyCapacity(usdt, 10)"
    );

    uni
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
        config.setPoolDecimals(uni, 27),
        "config.setPoolDecimals(uni, 27)"
    );
    await sendTxn(
        config.setPoolFeeFactor(uni, 10), //1/10000
        "config.setPoolFeeFactor(uni, 10)"
    );
    await sendTxn(
        config.setPoolBorrowCapacity(uni, 10**10), 
        "config.setPoolBorrowCapacity(uni, 10)"
    );
    await sendTxn(
        config.setPoolSupplyCapacity(uni, 10**10), 
        "config.setPoolSupplyCapacity(uni, 10)"
    );     
    const positionStoreUtils = await contractAtOptions("PositionStoreUtils", positionStoreUtilsAddress);
    const reader = await contractAtOptions("Reader", readerAddress, {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils
        },         
    });

    const dataStore = await contractAtOptions("DataStore", dataStoreAddress);
    const pools = await reader.getPools(dataStore.target, 0, 10);
    console.log(pools)



}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })