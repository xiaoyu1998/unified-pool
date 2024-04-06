import { contractAt, sendTxn, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidity, getDebt, getPositions} from "../utils/helper";

import { DepositUtils } from "../typechain-types/contracts/exchange/DepositHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  

    //execute repay
    const usdtDecimals = 6;
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const repayAmmount = expandDecimals(1200, usdtDecimals);
    await sendTxn(usdt.approve(router.target, repayAmmount), `usdt.approve(${router.target})`)


    const poolUsdt = await getPoolInfo(usdtAddress); 
    const params: DepositUtils.DepositParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: 0,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolUsdt.poolToken, repayAmmount]),
        exchangeRouter.interface.encodeFunctionData("executeRepay", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print 
    const poolUsdtAfterRepay = await getPoolInfo(usdtAddress); 
    const poolToken = await getContractAt("PoolToken", poolUsdtAfterRepay.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdtAfterRepay.debtToken);
    console.log("poolUsdtAfterRepay", poolUsdtAfterRepay);
    console.log("poolToken",await getLiquidity(poolToken, owner.address));
    console.log("debtToken",await getDebt(debtToken, owner.address)); 
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("userUnderlyingAsset",await usdt.balanceOf(owner.address)); 
    console.log("poolUnderlyingAsset",await usdt.balanceOf(poolToken.target)); 
    // console.log("price",await reader.getPrice(dataStore, usdtAddress)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })