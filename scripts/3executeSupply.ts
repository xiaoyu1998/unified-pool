import { contractAtOptions, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool, getLiquidity, getDebt} from "../utils/helper";

import { SupplyUtils } from "../typechain-types/contracts/exchange/SupplyHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const poolStoreUtils = await getContract("PoolStoreUtils");
    const positionStoreUtils = await getContract("PositionStoreUtils");
    const roleStore = await getContract("RoleStore");    
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");   
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");

    //approve allowances to the router
    const usdtAddress = getTokens("usdt");
    const usdt = await contractAtOptions("MintableToken", usdtAddress);
    const supplyAmmount = expandDecimals(1000, 6);
    await sendTxn(usdt.approve(router.target, supplyAmmount), `usdt.approve(${router.target})`)

    //execute supply
    const poolUsdt = await getPool(usdtAddress); 
    const params: SupplyUtils.SupplyParamsStruct = {
        underlyingAsset: usdtAddress,
        to: owner.address,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolUsdt.poolToken, supplyAmmount]),
        exchangeRouter.interface.encodeFunctionData("executeSupply", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolToken = await getContractAt("PoolToken", poolUsdt.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdt.debtToken);
    console.log("poolUsdt", poolUsdt);
    console.log("poolToken",await getLiquidity(poolToken, owner.address));
    console.log("debtToken",await getDebt(debtToken, owner.address)); 
    console.log("usdt",await usdt.balanceOf(owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })