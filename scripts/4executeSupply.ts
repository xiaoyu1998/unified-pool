const { contractAtOptions, sendTxn, getDeployedContractAddresses, getTokens, getContract } = require("../utils/deploy")
import { SupplyUtils } from "../typechain-types/contracts/exchange/SupplyHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const usdt = getTokens["usdt"];
    console.log(usdt);

    // const poolStoreUtils = await getContract("PoolStoreUtils");
    // const positionStoreUtils = await getContract("PositionStoreUtils");
    // const roleStore = await getContract("RoleStore");    
    // const dataStore = await getContract("DataStore");   
    // const reader = await getContract("Reader");   
    // const exchangeRouter = await getContract("ExchangeRouter"); 

    // const poolUsdt = await reader.getPool(dataStore.target, usdt);
    // const poolToken = poolUsdt[7];
    // const supplyAmmount = expandDecimals(10000, 6);

    // const params: SupplyUtils.SupplyParamsStruct = {
    //     underlyingAsset: usdt,
    //     receiver: owner.address,
    // };

    // const multicallArgs = [
    //     exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt, poolToken, supplyAmmount]),
    //     exchangeRouter.interface.encodeFunctionData("executeSupply", [params]),
    // ];






}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })