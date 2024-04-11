import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions} from "../utils/helper";

import { DepositUtils } from "../typechain-types/contracts/exchange/DepositHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Redeem", (pool, redeemer, to, amount) =>{
        console.log("eventEmitter Redeem" ,pool, redeemer, to, amount);
    }); 

    //execute repay
    const usdtDecimals = 6;
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const redeemAmmount = expandDecimals(1000, usdtDecimals);
 
    const poolUsdt = await getPoolInfo(usdtAddress); 
    const params: DepositUtils.DepositParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: redeemAmmount,
        to:owner.address
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeRedeem", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print 
    const poolUsdtAfterRedeem = await getPoolInfo(usdtAddress); 
    const poolToken = await getContractAt("PoolToken", poolUsdtAfterRedeem.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdtAfterRedeem.debtToken);
    console.log("poolUsdtAfterRedeem", poolUsdtAfterRedeem);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("userUSDT",await usdt.balanceOf(owner.address)); 
    console.log("poolUSDT",await usdt.balanceOf(poolToken.target)); 
    // console.log("price",await reader.getPrice(dataStore, usdtAddress)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })