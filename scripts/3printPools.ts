const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const poolStoreUtils = await contractAtOptions("PoolStoreUtils", "0x5FbDB2315678afecb367f032d93F642f64180aa3");
    const positionStoreUtils = await contractAtOptions("PositionStoreUtils", "0x610178dA211FEF7D417bC0e6FeD39F05609AD788");
    const reader = await contractAtOptions("Reader", "0xf5059a5D33d5853360D16C683c16e67980206f36", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils
        },         
    });


    const dataStore = await contractAtOptions("DataStore", "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512");


    const usdt = "0xa51c1fc2f0d1a1b8494ed1fe312d7c3a78ed91c0";
    const uni  = "0x0dcd1bf9a1b36ce34237eeafef220932846bcd82";

    console.log(reader);

    // const pools = await reader.staticCall.getPools(dataStore.target, 0, 10);
    // console.log(pools)
    // await reader.staticCall.getPool(dataStore.target, usdt);
    // await reader.staticCall.getPool(dataStore.target, uni);

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })