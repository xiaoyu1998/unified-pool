import * as Math from 'mathjs'
import bn from 'bignumber.js'
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 })

import {
    PERCENTAGE_FACTOR, 
    HALF_PERCENTAGE_FACTOR, 
    SECONDS_PER_YEAR, 
    PRECISION,
    HALF_PRECISION
} from "./constants"

export function bigNumberify(n) {
    // return ethers.toBigInt(n);
    return BigInt(n);
}

export function expandDecimals(n, decimals) {
    return bigNumberify(n)*(bigNumberify(10)**bigNumberify(decimals));
}

// returns the sqrt price as a 64x96
export function encodePriceSqrt(amount1: BigInt, amount0: BigInt): BigInt {
    return BigInt(
        new bn(amount1.toString())
          .div(amount0.toString())
          .sqrt()
          .multipliedBy(new bn(2).pow(96))
          .integerValue(3)
          .toString()
      )
}

export function decodePriceSqrt(sqrtPriceX96: BigInt): bn {
    return new bn((sqrtPriceX96 ** BigInt(2)).toString()).div(new bn(2).pow(192));
}

export function calcSilppage(
    amountOut: BigInt, 
    amountIn: BigInt, 
    sqrtPriceX96: BigInt,
    isZeroForOne:bool 
): BigInt {
    const currentPrice = bn(amountOut.toString())
                       .div(amountIn.toString());
    let startPrice = bn(decodePriceSqrt(sqrtPriceX96).toString());
    startPrice = isZeroForOne?startPrice:bn(1).div(startPrice);
    const deltaAbs = currentPrice.minus(startPrice).abs();
    return deltaAbs.div(currentPrice);
}

export function calcPriceImpact(
    amountOut: BigInt, 
    amountIn: BigInt, 
    sqrtPriceX96: BigInt,
    isZeroForOne:bool 
): BigInt {
    let startPrice = bn(decodePriceSqrt(sqrtPriceX96).toString());
    startPrice = isZeroForOne?startPrice:bn(1).div(startPrice);
    const quoteOutputAmount = startPrice.times(amountIn.toString());
    return (quoteOutputAmount.minus(amountOut.toString())).div(quoteOutputAmount);
}

export function calcFee(
    amount: BigInt, 
    feeAmount: BigInt, 
    feePercentageFactor: BigInt
): BigInt {
    return bn(amount.toString())
            .times(feeAmount.toString())
            .div(feePercentageFactor.toString());
            //TODO:should be feePercentageFactor - feeAmount in line95 /v3-core/contracts/libraries/SwapMath.sol
}

export function calcRates(
    ratebase, 
    optimalUsageRation, 
    rateSlop1, 
    rateSlop2, 
    availabeLiquidity, 
    totalDebt,
    feeFactor
) {
    const borrowUsageRatio = rayDiv(totalDebt, availabeLiquidity + totalDebt);

    let borrowRate = ratebase;
    if (borrowUsageRatio > optimalUsageRation) {
        const excessBorrowUsageRatio = rayDiv((borrowUsageRatio - optimalUsageRation), (PRECISION - optimalUsageRation));
        borrowRate += (rateSlop1 + rayMul(rateSlop2, excessBorrowUsageRatio));
    } else {
        borrowRate += rayDiv(rayMul(rateSlop1, borrowUsageRatio), optimalUsageRation);
    }

    const liquidityRate = percentMul(rayMul(borrowRate, borrowUsageRatio), PERCENTAGE_FACTOR - feeFactor);
    return {liquidityRate, borrowRate};
}

export function percentMul( value, percentage ): BigInt {
    return (value * percentage + HALF_PERCENTAGE_FACTOR)/PERCENTAGE_FACTOR;
}

export function calcInterest(rate, seconds): BigInt {  
    return PRECISION + (rate * seconds)/SECONDS_PER_YEAR;
}

export function calcFeeAmount(
    currTotalScaledDebt,
    currBorrowIndex,
    nextBorrowIndex,
    nextLiquidityIndex,
    feeFactor
): BigInt {
    const prevTotalDebt = rayMul(currTotalScaledDebt, currBorrowIndex);
    const currTotalDebt = rayMul(currTotalScaledDebt, nextBorrowIndex);
    const increaseTotalDebt = currTotalDebt - prevTotalDebt;
    const feeAmount = percentMul(increaseTotalDebt, feeFactor);
    console.log("feeAmount", feeAmount);
    console.log("nextLiquidityIndex", nextLiquidityIndex);

    return rayDiv(feeAmount, nextLiquidityIndex);
}

export function calcIndexes(
    currLiquidityIndex,
    currLiquidityRate,
    currBorrowIndex,
    currBorrowRate,
    interestPaymentPeriodInSeconds
) {
   const cumulatedLiquidityInterest = calcInterest(currLiquidityRate, interestPaymentPeriodInSeconds);
   const nextLiquidityIndex = rayMul(cumulatedLiquidityInterest, currLiquidityIndex);
   const cumulatedBorrowInterest = calcInterest(currBorrowRate, interestPaymentPeriodInSeconds);
   const nextBorrowIndex = rayMul(cumulatedBorrowInterest, currBorrowIndex);
   return {nextLiquidityIndex, nextBorrowIndex};
}

export function rayMul(a, b){
    console.log(typeof a, typeof b);
    return (a*b + HALF_PRECISION)/PRECISION;
}

export function rayDiv(a, b){
   return (a*PRECISION + b/bigNumberify(2))/b;
}

