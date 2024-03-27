const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const poolStoreUtils = await contractAtOptions("PoolStoreUtils", "0x5FbDB2315678afecb367f032d93F642f64180aa3");
    const poolFactory = await contractAtOptions("PoolFactory", "0x0165878A594ca255338adfa4d48449f69242Eb8F",{
        libraries: {
            PoolStoreUtils: poolStoreUtils
        },
    });
    //console.log(poolFactory.target);

    const usdt = "0xa51c1fc2f0d1a1b8494ed1fe312d7c3a78ed91c0";
    const uni  = "0x0dcd1bf9a1b36ce34237eeafef220932846bcd82";
    const strategy = "0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690";

    const configuration = 1;
    const poolUsdt = await sendTxn(
        poolFactory.createPool(usdt, strategy, configuration),
        "poolFactory.createPool(USDT)"
    );
    //console.log(poolUsdt);

    const poolUni = await sendTxn(
        poolFactory.createPool(uni, strategy, configuration),
        "poolFactory.createPool(Uni)"
    );
    //console.log(poolUni);
}


// async function main() {
//     const [owner] = await ethers.getSigners();
    
//     const poolFactory = await hre.ethers.getContract("PoolFactory");
//     console.log(poolFactory.address);

//     const strategy = await hre.ethers.getContract("PoolInterestRateStrategy");
//     const usdt = await hre.ethers.getContract("USDT");
//     const uni = await hre.ethers.getContract("UNI");


//     const configuration = 1;
//     const poolUsdt = await sendTxn(
//         poolFactory.createPool(
//             usdt.address, 
//             strategy.address,
//             configuration
//         ),
//         "poolFactory.createPool(USDT)"
//     );
//     console.log(poolUsdt);

//     const poolUni = await sendTxn(
//         poolFactory.createPool(
//             uni.address, 
//             strategy.address,
//             configuration
//         ),
//         "poolFactory.createPool(Uni)"
//     );
//     console.log(poolUni);
// }


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })