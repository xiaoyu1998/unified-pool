import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getMarginsAndSupplies,  getPositions} from "../utils/helper";
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
    const repayAmmount = expandDecimals(100000, usdtDecimals);
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
    //const tx = await exchangeRouter.multicall(multicallArgs);
    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    //print 
    const poolUsdtAfterRepay = await getPoolInfo(usdtAddress); 
    console.log("poolUsdtBeforeRepay", poolUsdt);
    console.log("poolUsdtAfterRepay", poolUsdtAfterRepay);
    console.log("marginsAndSupplies", await getMarginsAndSupplies(dataStore, reader, owner.address));
    console.log("positions", await getPositions(dataStore, reader, owner.address)); 
    console.log("poolUsdt",await usdt.balanceOf(poolUsdt.poolToken)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })