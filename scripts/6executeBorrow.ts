import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions, getPositionsInfo, getLiquidationHealthFactor} from "../utils/helper";
import { BorrowUtils } from "../typechain-types/contracts/exchange/BorrowHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Borrow", (pool, borrower, to, amount) =>{
        console.log("eventEmitter Borrow" ,pool, borrower, to, amount);
    }); 

    const config = await getContract("Config");
    //await config.setHealthFactorLiquidationThreshold(expandDecimals(110, 25))//110%

    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uni = await contractAt("MintableToken", uniAddress);

    //borrow usdt
    const borrowAmmountUsdt = expandDecimals(2000000, usdtDecimals);
    const paramsUsdt: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: borrowAmmountUsdt,
    };
    
    //borrow uni
    const borrowAmmountUni = expandDecimals(100000, uniDecimals);
    const paramsUni: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: uniAddress,
        amount: borrowAmmountUni,
    };

    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsUni]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolUsdt = await getPoolInfo(usdtAddress); 
    const poolUni = await getPoolInfo(uniAddress); 
    // const poolToken = await getContractAt("PoolToken", poolUsdt.poolToken);
    // const debtToken = await getContractAt("DebtToken", poolUsdt.debtToken);
    console.log("poolUsdt", poolUsdt);
    console.log("poolUni", poolUni);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("positionsInfo",await getPositionsInfo(dataStore, reader, owner.address)); 
    //console.log("liquidationHealthFactor",await getLiquidationHealthFactor( owner.address)); 
    // console.log("userUsdt",await usdt.balanceOf(owner.address)); 
    // console.log("userUni",await uni.balanceOf(owner.address)); 
    console.log("poolUsdt",await usdt.balanceOf(poolUsdt.poolToken)); 
    console.log("poolUni",await uni.balanceOf(poolUni.poolToken)); 
    // console.log("price",await reader.getPrice(dataStore, usdtAddress)); 
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })