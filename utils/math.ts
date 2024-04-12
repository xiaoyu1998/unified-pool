import * as Math from 'mathjs'

export function bigNumberify(n) {
  // return ethers.toBigInt(n);
  return BigInt(n);
}

export function expandDecimals(n, decimals) {
  return bigNumberify(n)*(bigNumberify(10)**ethers.toBigInt(decimals));
}

// returns the sqrt price as a 64x96
export function encodePriceSqrt(amount1: BigInt, amount0: BigInt): BigInt {
  const numerator = amount1 << BigInt(192);
  const denominator = amount0;
  const ratioX192 = numerator / denominator;
  return BigInt(Math.sqrt(ratioX192.toString()));
}

export function decodePriceSqrt(sqrtPriceX96: BigInt): BigInt {
   return (sqrtPriceX96 ** BigInt(2)) >> BigInt(192);
}