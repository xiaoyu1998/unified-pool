import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt } from "../utils/math";
import { getPoolsInfo, getLiquidityAndDebts, getPositions, getPositionsInfo} from "../utils/helper";

async function main() {
    const [owner] = await ethers.getSigners();

    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  

    console.log("Assets", await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions", await getPositions(dataStore, reader, owner.address)); 
    console.log("positionsInfo", await getPositionsInfo(dataStore, reader, owner.address)); 
    console.log("pools", await getPoolsInfo(dataStore, reader));

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })