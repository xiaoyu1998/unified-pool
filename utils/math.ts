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

     //return BigInt(Math.sqrt((amount1/amount0).toString())) << BigInt(96);
}

export function decodePriceSqrt(sqrtPriceX96: BigInt): BigInt {
   return (sqrtPriceX96 ** BigInt(2)) >> BigInt(192);
}