import { contractAt, sendTxn, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool, getLiquidity, getDebt, getPositions} from "../utils/helper";

import { DepositUtils } from "../typechain-types/contracts/exchange/DepositHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    
    //approve allowances to the router
    const usdtDecimals = 6;
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const depositAmmount = expandDecimals(12000, usdtDecimals);
    await sendTxn(usdt.approve(router.target, depositAmmount), `usdt.approve(${router.target})`)

    //execute deposit
    const poolUsdt = await getPool(usdtAddress); 
    const params: DepositUtils.DepositParamsStruct = {
        underlyingAsset: usdtAddress,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolUsdt.poolToken, depositAmmount]),
        exchangeRouter.interface.encodeFunctionData("executeDeposit", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolUsdtAfterDeposit = await getPool(usdtAddress);
    const poolToken = await getContractAt("PoolToken", poolUsdtAfterDeposit.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdtAfterDeposit.debtToken);
    console.log("poolUsdtAfterDeposit", poolUsdtAfterDeposit);
    console.log("poolToken",await getLiquidity(poolToken, owner.address));
    console.log("debtToken",await getDebt(debtToken, owner.address)); 
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("userUnderlyingAsset",await usdt.balanceOf(owner.address)); 
    console.log("poolUnderlyingAsset",await usdt.balanceOf(poolToken.target)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })