import { contractAt, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions} from "../utils/helper";

import { SwapUtils } from "../typechain-types/contracts/exchange/SwapHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Swap", (underlyingAssetIn, underlyingAssetOut, account, amountIn, amountOut) =>{
        console.log("eventEmitter Swap" ,underlyingAssetIn, underlyingAssetOut, account, amountIn, amountOut);
    });

    const usdtDecimals = getTokens("USDT")["decimals"];
    const uniDecimals = getTokens("UNI")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uni = await contractAt("MintableToken", uniAddress);

    console.log("usdtAddress",  usdtAddress);
    console.log("uniAddress",  uniAddress);

    //execute swap
    const params: SwapUtils.SwapParamsStruct = {
        underlyingAssetIn: usdtAddress,
        underlyingAssetOut: uniAddress,
        amount: expandDecimals(100000, usdtDecimals),
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeSwapExactIn", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);

    //print 
    const poolUsdtAfterSwap = await getPoolInfo(usdtAddress); 
    const poolUniAfterSwap = await getPoolInfo(uniAddress); 
    console.log("poolUsdtAfterSwap", poolUsdtAfterSwap);
    console.log("poolUniAfterSwap", poolUniAfterSwap);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })