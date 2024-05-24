import * as Math from 'mathjs'
import bn from 'bignumber.js'
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 })

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
    return deltaAbs.div(startPrice);
}

export function calcPriceImpact(
    amountOut: BigInt, 
    amountIn: BigInt, 
    sqrtPriceX96: BigInt,
    isZeroForOne:bool 
): BigInt {
    let startPrice = bn(decodePriceSqrt(sqrtPriceX96).toString());
    startPrice = isZeroForOne?startPrice:bn(1).div(startPrice);
    const quoteOutputAmount = startPrice.times(bn(amountIn.toString()));
    return (quoteOutputAmount.minus(bn(amountOut.toString()))).div(quoteOutputAmount);
}