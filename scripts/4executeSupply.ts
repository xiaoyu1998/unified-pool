import { contractAtOptions, sendTxn, getDeployedContractAddresses, getTokens, getContract } from "../utils/deploy";
import { expandDecimals } from "../utils/math";

import { SupplyUtils } from "../typechain-types/contracts/exchange/SupplyHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const usdtAddress = getTokens("usdt");
    console.log(usdtAddress);

    const poolStoreUtils = await getContract("PoolStoreUtils");
    const positionStoreUtils = await getContract("PositionStoreUtils");
    const roleStore = await getContract("RoleStore");    
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");   
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");


    const usdt = await contractAtOptions("MintableToken", usdtAddress);
    //console.log(await usdt.allowance(owner.address, exchangeRouter.target));
    await sendTxn(usdt.approve(router.target, expandDecimals(1000000, 6)), `usdt.approve(${router.target})`)

    const poolUsdt = await reader.getPool(dataStore.target, usdtAddress);
    const poolToken = poolUsdt[7];
    const supplyAmmount = expandDecimals(1000, 6);

    const params: SupplyUtils.SupplyParamsStruct = {
        underlyingAsset: usdtAddress,
        receiver: owner.address,
    };

    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolToken, supplyAmmount]),
        exchangeRouter.interface.encodeFunctionData("executeSupply", [params]),
    ];


   const tx = await exchangeRouter.multicall(multicallArgs);   

   const pool = await reader.getPool(dataStore.target, usdtAddress);
   console.log(pool)


}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })