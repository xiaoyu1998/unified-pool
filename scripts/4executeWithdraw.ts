import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
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
    const poolUsdt = await getPoolInfo(usdtAddress); 
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
    const poolUni = await getPoolInfo(uniAddress); 
    const paramsUni: WithdrawUtils.WithdrawParamsStruct = {
        underlyingAsset: uniAddress,
        amount: withdrawAmmountUni,
        to: owner.address,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeWithdraw", [paramsUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeWithdraw", [paramsUni]),
    ];
    // const tx = await exchangeRouter.multicall(multicallArgs);  
    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    //print poolUsdt
    console.log("poolUsdtAfterWithdraw", getPoolInfo(usdtAddress));
    console.log("account", await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("poolUsdt",await usdt.balanceOf(poolUsdt.poolToken)); 
    console.log("poolUni",await uni.balanceOf(poolUni.poolToken)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })