import { contractAt, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool, getLiquidity, getDebt} from "../utils/helper";
import { WithdrawUtils } from "../typechain-types/contracts/exchange/SupplyHandler";

// ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR);
async function main() {
    const [owner] = await ethers.getSigners();


    const poolStoreUtilsAddress = getDeployedContractAddresses("PositionStoreUtils");
    return await contractAt("PositionStoreUtils", poolStoreUtilsAddress);

    // const configAddress = getDeployedContractAddresses("Config");
    // return await contractAtOptions("Config", configAddress, {
    //     libraries: {
    //         PoolStoreUtils: poolStoreUtils,
    //     },         
    // });  

    // const dataStore = getDeployedContractAddresses("DataStore");
    // return await contractAtOptions("DataStore", dataStore);

    // const router = getDeployedContractAddresses("ExchangeRouter");
    // return await contractAtOptions("BaseRouter", router);



}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })