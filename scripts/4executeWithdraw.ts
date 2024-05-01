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

    //withdraw usdt
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const withdrawAmmountUsdt = expandDecimals(1000, usdtDecimals);
    const paramsUsdt: WithdrawUtils.WithdrawParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: withdrawAmmountUsdt,
        to: owner.address,
    };

    //withdraw uni
    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);
    const withdrawAmmountUni = expandDecimals(1000, uniDecimals);
    const paramsUni: WithdrawUtils.WithdrawParamsStruct = {
        underlyingAsset: uniAddress,
        amount: withdrawAmmountUni,
        to: owner.address,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeWithdraw", [paramsUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeWithdraw", [paramsUni]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolUsdtAfterWithdraw = await getPoolInfo(usdtAddress); 
    const poolToken = await getContractAt("PoolToken", poolUsdtAfterWithdraw.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdtAfterWithdraw.debtToken);
    console.log("poolUsdtAfterWithdraw", poolUsdtAfterWithdraw);
    console.log("account", await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("poolUSDT", await usdt.balanceOf(poolToken.target)); 
    console.log("userUSDT", await usdt.balanceOf(owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })