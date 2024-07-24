import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt,calcPriceImpact, calcSilppage, calcSqrtPriceLimitX96} from "../utils/math";
import { getPoolsInfo, getLiquidityAndDebts, getPositions, getPositionsInfo, getLiquidationHealthFactor, getMarginsAndSupplies} from "../utils/helper";

// async function main() {
//     const [owner] = await ethers.getSigners();

//     console.log("owner", owner);

//     const usdtDecimals = getTokens("USDT")["decimals"];
//     const usdtAddress = getTokens("USDT")["address"];
//     const usdt = await contractAt("MintableToken", usdtAddress);
//     const uniDecimals = getTokens("UNI")["decimals"];
//     const uniAddress = getTokens("UNI")["address"];
//     const uni = await contractAt("MintableToken", uniAddress);
//     const dataStore = await getContract("DataStore");   
//     const reader = await getContract("Reader");  
//     const uniIsZero =  (uniAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;

//     //
//     const feeAmount = await reader.getDexPoolFeeAmount(dataStore, uniAddress, usdtAddress);
//     const quoterAddress = "0xFCb9aB7bBf155F5d76de65a2ae429aB5CCEdeA69";
//     const quoter = await contractAt("Quoter", quoterAddress);
//     const uniAmountIn = expandDecimals(10000, uniDecimals);
//     const [usdtAmountOut, startSqrtPriceX96] = await quoter.quoteExactInputSingle.staticCall(
//         uniAddress, 
//         usdtAddress,
//         feeAmount,
//         uniAmountIn,
//         0 //the max sqrtPriceLimitX96 
//     );
//     console.log("priceImpact", calcPriceImpact(usdtAmountOut, uniAmountIn, startSqrtPriceX96, uniIsZero).toString()); 
//     console.log("silppage", calcSilppage(usdtAmountOut, uniAmountIn, startSqrtPriceX96, uniIsZero).toString()); //delete feeAmount in amountIn to get the silppage without fee
//     console.log("startSqrtPriceX96", startSqrtPriceX96, "sqrtPriceLimitX96", calcSqrtPriceLimitX96(startSqrtPriceX96, "0.05", uniIsZero).toString());


//     console.log("account", await getMarginsAndSupplies(dataStore, reader, owner.address));
//     console.log("positions", await getPositions(dataStore, reader, owner.address)); 
//     console.log("positionsInfo", await getPositionsInfo(dataStore, reader, owner.address)); 
//     console.log("pools", await getPoolsInfo(dataStore, reader));
//     console.log("HealthFactor", await getLiquidationHealthFactor(owner.address));
//     console.log("userUSDT", await usdt.balanceOf(owner.address)); 
//     console.log("userUNI", await uni.balanceOf(owner.address)); 

// }

async function main() {
    const [owner] = await ethers.getSigners();
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");   
    const defundPool = "0x0bA553e6c99b9592768363F2cF77378725BBD2Ec"
    console.log("positions", await getPositions(dataStore, reader, defundPool));   
    console.log("account", await getMarginsAndSupplies(dataStore, reader, defundPool)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })