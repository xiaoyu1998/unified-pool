import { contractAt, sendTxn, getTokens, getContract, getEventEmitter,contractAtOptions } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt,calcPriceImpact, calcSilppage, calcSqrtPriceLimitX96, rayMul} from "../utils/math";
import { getPoolsInfo, getPoolInfo, getPool, getAssets, getPositions, getPositionsInfo, getLiquidationHealthFactor } from "../utils/helper";

async function main() {
    const [owner] = await ethers.getSigners();

    //console.log("owner", owner);
    const address = getTokens("UNI")["address"];
    const token = await contractAt("MintableToken", address);
    //console.log("pools", await getPoolInfo(address));
    const pool = await getPool(address);
    console.log("pool", pool);

    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const poolStoreUtils = await getContract("PoolStoreUtils")
    const poolToken = await contractAtOptions("PoolToken", "0x81bBEBE1a77574e456010539c0e7e94D24bEA9CD", {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
            },         
        });
    const debtToken = await contractAtOptions("DebtToken", "0xDE5A5cc54267CeE1cAbaCA1c9a8064f0938b2d20",{
            libraries: {
                PoolStoreUtils: poolStoreUtils,
            },         
        });
    
    console.log("balance", await token.balanceOf(poolToken.target));
    console.log("scaledTotalSupply", await poolToken.scaledTotalSupply());
    console.log("scaledTotalDebt", await debtToken.scaledTotalSupply());
    console.log("totalCollateral", await poolToken.totalCollateral());
    //console.log("availableLiquidity", await poolToken.availableLiquidity(0));
    console.log("totalSupply", await poolToken.totalSupply());
    console.log("totalSupply", rayMul(await poolToken.scaledTotalSupply(), pool.liquidityIndex));
    console.log("totalDebt", await debtToken.totalSupply());
    console.log("totalDebt", rayMul(await debtToken.scaledTotalSupply(), pool.borrowIndex));


    const strategy = await getContract("PoolInterestRateStrategy")
    console.log("ratebase", await strategy.getRatebase());
    console.log("optimalUsageRatio", await strategy.getOptimalUsageRatio());
    console.log("rateSlope1", await strategy.getRateSlope1());
    console.log("rateSlope2", await strategy.getRateSlope2());

    // const usdtDecimals = getTokens("USDT")["decimals"];
    // const usdtAddress = getTokens("USDT")["address"];
    // const usdt = await contractAt("MintableToken", usdtAddress);
    // const uniDecimals = getTokens("UNI")["decimals"];
    // const uniAddress = getTokens("UNI")["address"];
    // const uni = await contractAt("MintableToken", uniAddress);
    // const dataStore = await getContract("DataStore");   
    // const reader = await getContract("Reader");  
    // const uniIsZero =  (uniAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;

    // //
    // const feeAmount = await reader.getDexPoolFeeAmount(dataStore, uniAddress, usdtAddress);
    // const quoterAddress = "0xFCb9aB7bBf155F5d76de65a2ae429aB5CCEdeA69";
    // const quoter = await contractAt("Quoter", quoterAddress);
    // const uniAmountIn = expandDecimals(10000, uniDecimals);
    // const [usdtAmountOut, startSqrtPriceX96] = await quoter.quoteExactInputSingle.staticCall(
    //     uniAddress, 
    //     usdtAddress,
    //     feeAmount,
    //     uniAmountIn,
    //     0 //the max sqrtPriceLimitX96 
    // );
    // console.log("priceImpact", calcPriceImpact(usdtAmountOut, uniAmountIn, startSqrtPriceX96, uniIsZero).toString()); 
    // console.log("silppage", calcSilppage(usdtAmountOut, uniAmountIn, startSqrtPriceX96, uniIsZero).toString()); //delete feeAmount in amountIn to get the silppage without fee
    // console.log("startSqrtPriceX96", startSqrtPriceX96, "sqrtPriceLimitX96", calcSqrtPriceLimitX96(startSqrtPriceX96, "0.05", uniIsZero).toString());


    // console.log("assets", await getAssets(dataStore, reader, owner.address));
    // console.log("positions", await getPositions(dataStore, reader, owner.address)); 
    // console.log("positionsInfo", await getPositionsInfo(dataStore, reader, owner.address)); 
    // console.log("pools", await getPoolsInfo(dataStore, reader));
    // console.log("HealthFactor", await getLiquidationHealthFactor(owner.address));
    // console.log("userUSDT", await usdt.balanceOf(owner.address)); 
    // console.log("userUNI", await uni.balanceOf(owner.address)); 

}

// async function main() {
//     const [owner] = await ethers.getSigners();
//     const dataStore = await getContract("DataStore");   
//     const reader = await getContract("Reader");   
//     const defundPool = "0x0bA553e6c99b9592768363F2cF77378725BBD2Ec"
//     console.log("positions", await getPositions(dataStore, reader, defundPool));   
//     console.log("assets", await getAssets(dataStore, reader, defundPool)); 

// }


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })