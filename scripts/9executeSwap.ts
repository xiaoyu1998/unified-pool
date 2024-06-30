import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt, calcSqrtPriceLimitX96, calcPriceImpact } from "../utils/math";
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
    // const isZeroForOne =  (usdtAddress.toLowerCase() < uniAddress.toLowerCase()) ? true:false;
    // const feeAmount = await reader.getDexPoolFeeAmount(dataStore, uniAddress, usdtAddress);
    // const quoterAddress = "0xFCb9aB7bBf155F5d76de65a2ae429aB5CCEdeA69";
    // const quoter = await contractAt("Quoter", quoterAddress);
    // const usdtAmountIn = expandDecimals(10000, usdtDecimals);
    // const [uniAmountOut, startSqrtPriceX96] = await quoter.quoteExactInputSingle.staticCall(
    //     usdtAddress,
    //     uniAddress, 
    //     feeAmount,
    //     usdtAmountIn,
    //     0
    // );

    // const sqrtPriceLimitX96 = calcSqrtPriceLimitX96(startSqrtPriceX96, "0.05", isZeroForOne);
    // console.log("isUsdtZero", isZeroForOne);
    // console.log("startSqrtPriceX96", startSqrtPriceX96.toString()); 
    // console.log("sqrtPriceLimitX96", sqrtPriceLimitX96.toString()); 
    //console.log("priceImpact", calcPriceImpact(uniAmountOut, usdtAmountIn, startSqrtPriceX96, isZeroForOne).toString()); 

    //execute borrow
    // const borrowAmmount = expandDecimals(10000, usdtDecimals);
    // const paramsBorrow: BorrowUtils.BorrowParamsStruct = {
    //     underlyingAsset: usdtAddress,
    //     amount: borrowAmmount,
    // };

    //execute swap
    const params: SwapUtils.SwapParamsStruct = {
        underlyingAssetIn: usdtAddress,
        underlyingAssetOut: uniAddress,
        amount: expandDecimals(30000, usdtDecimals),
        sqrtPriceLimitX96: 0
        //sqrtPriceLimitX96: sqrtPriceLimitX96
    };
    const multicallArgs = [
        // exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsBorrow]),
        exchangeRouter.interface.encodeFunctionData("executeSwap", [params]),
    ];
    //const tx = await exchangeRouter.multicall.staticCall(multicallArgs);
    await sendTxn(
        exchangeRouter.multicall(multicallArgs, {
            gasLimit:3000000,
        }),
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