const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const poolStoreUtils = await contractAtOptions("PoolStoreUtils", "0xb7278A61aa25c888815aFC32Ad3cC52fF24fE575");
    const positionStoreUtils = await contractAtOptions("PositionStoreUtils", "0xCD8a1C3ba11CF5ECfa6267617243239504a98d90");
    const reader = await contractAtOptions("Reader", "0xBEc49fA140aCaA83533fB00A2BB19bDdd0290f25", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils
        },         
    });


    const dataStore = await contractAtOptions("DataStore", "0x162A433068F51e18b7d13932F27e66a3f99E6890");


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