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
    const usdtAddress = getTokens("usdt")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const depositAmmount = expandDecimals(1000, 6);
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
    const poolToken = await getContractAt("PoolToken", poolUsdt.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdt.debtToken);
    console.log("poolUsdt", poolUsdt);
    console.log("poolToken",await getLiquidity(poolToken, owner.address));
    console.log("debtToken",await getDebt(debtToken, owner.address)); 
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("usdt",await usdt.balanceOf(owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })