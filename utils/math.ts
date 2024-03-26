
export function bigNumberify(n) {
  // return ethers.toBigInt(n);
  return BigInt(n);
}

export function expandDecimals(n, decimals) {
  return bigNumberify(n)*(bigNumberify(10)**ethers.toBigInt(decimals));
}