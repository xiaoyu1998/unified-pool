import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt, calcSqrtPriceLimitX96 } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions} from "../utils/helper";
import { SwapUtils } from "../typechain-types/contracts/exchange/SwapHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Swap", (
        underlyingAssetIn, 
        underlyingAssetOut, 
        account,
        amountIn, 
        amountOut, 
        fee,
        collateralIn,
        debtScaledIn,
        collateralOut,
        debtScaledOut
        ) =>{
        console.log("eventEmitter Swap" ,underlyingAssetIn, underlyingAssetOut, account, amountIn, amountOut, fee, collateralIn, debtScaledIn, collateralOut, debtScaledOut);
    });

    const usdtDecimals = getTokens("USDT")["decimals"];
    const uniDecimals = getTokens("UNI")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uni = await contractAt("MintableToken", uniAddress);

    //
    const usdtIsZero =  (usdtAddress.toLowerCase() < uniAddress.toLowerCase()) ? true:false;
    const feeAmount = await reader.getDexPoolFeeAmount(dataStore, uniAddress, usdtAddress);
    const quoterAddress = "0xF85895D097B2C25946BB95C4d11E2F3c035F8f0C";
    const quoter = await contractAt("Quoter", quoterAddress);
    const uniAmountIn = expandDecimals(1000, uniDecimals);
    const [usdtAmountOut, startSqrtPriceX96] = await quoter.quoteExactInputSingle.staticCall(
        usdtAddress,
        uniAddress, 
        feeAmount,
        uniAmountIn,
        0
    );

    const sqrtPriceLimitX96 = calcSqrtPriceLimitX96(startSqrtPriceX96, "0.05", usdtIsZero).toString();

    //execute swap
    const params: SwapUtils.SwapParamsStruct = {
        underlyingAssetIn: usdtAddress,
        underlyingAssetOut: uniAddress,
        amount: expandDecimals(10000, usdtDecimals),
        //sqrtPriceLimitX96: BigInt("257050102320719215204012")
        sqrtPriceLimitX96: sqrtPriceLimitX96
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeSwap", [params]),
    ];
    //const tx = await exchangeRouter.multicall.staticCall(multicallArgs);
    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    //print 
    const poolUsdtAfterSwap = await getPoolInfo(usdtAddress); 
    const poolUniAfterSwap = await getPoolInfo(uniAddress); 
    console.log("poolUsdtAfterSwap", poolUsdtAfterSwap);
    console.log("poolUniAfterSwap", poolUniAfterSwap);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("poolUsdt",await usdt.balanceOf(poolUsdtAfterSwap.poolToken)); 
    console.log("poolUni",await uni.balanceOf(poolUniAfterSwap.poolToken));     

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })