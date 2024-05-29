import * as Math from 'mathjs'
import bn from 'bignumber.js'
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 })

import {
    PERCENTAGE_FACTOR, 
    HALF_PERCENTAGE_FACTOR, 
    SECONDS_PER_YEAR, 
    PRECISION
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
    //const PRECISION = expandDecimals(1, 27);
    const borrowUsageRatio = BigInt(
        new bn(totalDebt.toString())
        .div((availabeLiquidity + totalDebt).toString())
        .multipliedBy(PRECISION.toString()).toString()
    );

    let borrowRate = ratebase;
    if (borrowUsageRatio > optimalUsageRation) {
        const excessBorrowUsageRatio = (borrowUsageRatio - optimalUsageRation)*PRECISION/(PRECISION - optimalUsageRation);
        borrowRate += (rateSlop1 + rateSlop2*excessBorrowUsageRatio/PRECISION);
    } else {
        borrowRate += rateSlop1*borrowUsageRatio/optimalUsageRation;
    }

    const liquidityRate = percentMul(borrowRate*borrowUsageRatio/PRECISION, PERCENTAGE_FACTOR - feeFactor);
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
    const prevTotalDebt = currTotalScaledDebt*currBorrowIndex/PRECISION;
    const currTotalDebt = currTotalScaledDebt*nextBorrowIndex/PRECISION;
    const increaseTotalDebt = currTotalDebt - prevTotalDebt;
    const feeAmount = percentMul(increaseTotalDebt, feeFactor);

    return feeAmount/nextLiquidityIndex*PRECISION;
}

export function calcIndexes(
    currLiquidityIndex,
    currLiquidityRate,
    currBorrowIndex,
    currBorrowRate,
    interestPaymentPeriodInSeconds
) {
   //const PRECISION = expandDecimals(1, 27);
   const cumulatedLiquidityInterest = calcInterest(currLiquidityRate, interestPaymentPeriodInSeconds);
   const nextLiquidityIndex = cumulatedLiquidityInterest*currLiquidityIndex/PRECISION;
   const cumulatedBorrowInterest = calcInterest(currBorrowRate, interestPaymentPeriodInSeconds);
   const nextBorrowIndex = cumulatedBorrowInterest*currBorrowIndex/PRECISION;

   console.log("currLiquidityRate", currLiquidityRate);
   console.log("interestPaymentPeriodInSeconds", interestPaymentPeriodInSeconds);
   console.log("SECONDS_PER_YEAR", SECONDS_PER_YEAR);
   console.log("result", currLiquidityRate*interestPaymentPeriodInSeconds);
   console.log("cumulatedLiquidityInterest", PRECISION + currLiquidityRate*interestPaymentPeriodInSeconds/SECONDS_PER_YEAR);

   console.log("cumulatedLiquidityInterest", cumulatedLiquidityInterest);
   console.log("cumulatedBorrowInterest", cumulatedBorrowInterest);

   return {nextLiquidityIndex, nextBorrowIndex};
}

