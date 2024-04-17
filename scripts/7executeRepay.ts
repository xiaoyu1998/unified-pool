import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts,  getPositions} from "../utils/helper";

import { RepaytUtils } from "../typechain-types/contracts/exchange/RepaytHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Repay", (pool, repayer, to, amount) =>{
        console.log("eventEmitter Repay" ,pool, repayer, to, amount);
    });

    //execute repay
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const repayAmmount = expandDecimals(1200, usdtDecimals);
    await sendTxn(usdt.approve(router.target, repayAmmount), `usdt.approve(${router.target})`)

    const poolUsdt = await getPoolInfo(usdtAddress); 
    const params: RepaytUtils.RepayParamsStruct = {
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
    console.log("account", await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions", await getPositions(dataStore, reader, owner.address)); 
    console.log("userUSDT", await usdt.balanceOf(owner.address)); 
    console.log("poolUSDT", await usdt.balanceOf(poolToken.target)); 
    // console.log("price",await reader.getPrice(dataStore, usdtAddress)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })