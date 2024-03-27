const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const poolStoreUtils = await contractAtOptions("PoolStoreUtils", "0xb7278A61aa25c888815aFC32Ad3cC52fF24fE575");
    const poolFactory = await contractAtOptions("PoolFactory", "0xf4B146FbA71F41E0592668ffbF264F1D186b2Ca8",{
        libraries: {
            PoolStoreUtils: poolStoreUtils
        },
    });

    const usdt = "0xc9a43158891282a2b1475592d5719c001986aaec";
    const uni  = "0x1c85638e118b37167e9298c2268758e058ddfda0";
    const strategy = "0x4EE6eCAD1c2Dae9f525404De8555724e3c35d07B";
    const configuration = 1;
    // await sendTxn(
    //     poolFactory.createPool(usdt, strategy, configuration),
    //     "poolFactory.createPool(USDT)"
    // );
    // await sendTxn(
    //     poolFactory.createPool(uni, strategy, configuration),
    //     "poolFactory.createPool(Uni)"
    // );


    //console.log(poolFactory.target);
    const config = await contractAtOptions("Config", "0x202CCe504e04bEd6fC0521238dDf04Bc9E8E15aB",{
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

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })