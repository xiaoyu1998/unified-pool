const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const poolStoreUtils = await contractAtOptions("PoolStoreUtils", "0x5FbDB2315678afecb367f032d93F642f64180aa3");
    const positionStoreUtils = await contractAtOptions("PositionStoreUtils", "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0");
    const reader = await contractAtOptions("Reader", "0xa82fF9aFd8f496c3d6ac40E2a0F282E47488CFc9", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils
        },         
    });


    const dataStore = await contractAtOptions("DataStore", "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9");


    const usdt = "0xc9a43158891282a2b1475592d5719c001986aaec";
    const uni  = "0x1c85638e118b37167e9298c2268758e058ddfda0";
    //console.log(reader);

    const pools = await reader.getPools(dataStore.target, 0, 10);
    console.log(pools)
    //const poolUsdt = await reader.getPool(dataStore.target, usdt);
    // await reader.staticCall.getPool(dataStore.target, uni);

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })