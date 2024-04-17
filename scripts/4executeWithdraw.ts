import { contractAt, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts } from "../utils/helper";

import { WithdrawUtils } from "../typechain-types/contracts/exchange/SupplyHandler";

async function main() {
    const [owner] = await ethers.getSigners();
     
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Withdraw", (pool, withdrawer, to, amount) =>{
        console.log("eventEmitter Withdraw" ,pool, withdrawer, to, amount);
    }); 

    //execute withdraw
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    //const poolUsdt = await getPoolInfo(usdtAddress); 
    const withdrawAmmount = expandDecimals(1000, usdtDecimals);
    const params: WithdrawUtils.WithdrawParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: withdrawAmmount,
        to: owner.address,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeWithdraw", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolUsdtAfterWithdraw = await getPoolInfo(usdtAddress); 
    const poolToken = await getContractAt("PoolToken", poolUsdtAfterWithdraw.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdtAfterWithdraw.debtToken);
    console.log("poolUsdtAfterWithdraw", poolUsdtAfterWithdraw);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("userUSDT",await usdt.balanceOf(owner.address)); 
    console.log("poolUSDT",await usdt.balanceOf(poolToken.target)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })