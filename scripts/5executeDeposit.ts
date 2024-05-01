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
    eventEmitter.on("Deposit", (pool, depositer, amount) =>{
        console.log("eventEmitter Deposit" ,pool, depositer, amount);
    }); 
    
    //approve allowances to the router
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const depositAmmountUsdt = expandDecimals(1000000, usdtDecimals);
    await sendTxn(usdt.approve(router.target, depositAmmountUsdt), `usdt.approve(${router.target})`)

    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);
    const depositAmmountUni = expandDecimals(10000, uniDecimals);
    await sendTxn(uni.approve(router.target, depositAmmountUni), `uni.approve(${router.target})`)
    
    //execute deposit
    const poolUsdt = await getPoolInfo(usdtAddress); 
    const paramsUsdt: DepositUtils.DepositParamsStruct = {
        underlyingAsset: usdtAddress,
    };
    const poolUni = await getPoolInfo(uniAddress); 
    const paramsUni: DepositUtils.DepositParamsStruct = {
        underlyingAsset: uniAddress,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolUsdt.poolToken, depositAmmountUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeDeposit", [paramsUsdt]),
        exchangeRouter.interface.encodeFunctionData("sendTokens", [uniAddress, poolUni.poolToken, depositAmmountUni]),
        exchangeRouter.interface.encodeFunctionData("executeDeposit", [paramsUni]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolUsdtAfterDeposit = await getPoolInfo(usdtAddress);
    const poolToken = await getContractAt("PoolToken", poolUsdtAfterDeposit.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdtAfterDeposit.debtToken);
    console.log("poolUsdtAfterDeposit", poolUsdtAfterDeposit);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("userUsdt",await usdt.balanceOf(owner.address)); 
    console.log("poolUsdt",await usdt.balanceOf(poolUsdt.poolToken)); 
    console.log("userUni",await uni.balanceOf(owner.address)); 
    console.log("poolUni",await uni.balanceOf(poolUni.poolToken)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })