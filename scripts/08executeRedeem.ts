import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getAssets, getPositions, getMaxAmountToRedeem} from "../utils/helper";
import { RedeemUtils } from "../typechain-types/contracts/exchange/RedeemHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Redeem", (pool, redeemer, to, amount, collateral, debtScaled) =>{
        console.log("eventEmitter Redeem" ,pool, redeemer, to, amount, collateral, debtScaled);
    }); 

    //execute repay
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const redeemAmmount = expandDecimals(800000, usdtDecimals);
 
    const poolUsdt = await getPoolInfo(usdtAddress); 
    const params: RedeemUtils.RedeemParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: redeemAmmount,
        to:owner.address
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeRedeem", [params]),
    ];
    //const tx = await exchangeRouter.multicall(multicallArgs);
    await sendTxn(
        exchangeRouter.multicall(multicallArgs, {
            gasLimit:2000000,
        }),
        "exchangeRouter.multicall"
    );

    //print 
    const poolUsdtAfterRedeem = await getPoolInfo(usdtAddress); 
    console.log("poolUsdtBeforeRedeem", poolUsdt);
    console.log("poolUsdtAfterRedeem", poolUsdtAfterRedeem);
    console.log("assets",await getAssets(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address));
    console.log("maxAmountToRedeem",await getMaxAmountToRedeem(dataStore, reader, owner.address, usdtAddress)); 
    console.log("poolUsdt",await usdt.balanceOf(poolUsdt.poolToken)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })