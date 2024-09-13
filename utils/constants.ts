export const MaxUint128 = BigInt(2)**BigInt(128) - BigInt(1);
export const MaxUint256 = BigInt(2)**BigInt(256) - BigInt(1);
export const FeePercentageFactor = BigInt(1000000);

export enum FeeAmount {
  LOW = 500,
  MEDIUM = 3000,
  HIGH = 10000,
}

export const TICK_SPACINGS: { [amount in FeeAmount]: number } = {
  [FeeAmount.LOW]: 10,
  [FeeAmount.MEDIUM]: 60,
  [FeeAmount.HIGH]: 200,
}

export const usdtDecimals = 6;
export const usdtOracleDecimals = 24;
export const uniDecimals = 18;
export const uniOracleDecimals = 12;
export const ethDecimals = 18;
export const ethOracleDecimals = 12;
export const tokenDecimals = 18;
export const tokenOracleDecimals = 12;

export const MIN_SQRT_RATIO = BigInt('4295128739')
export const MAX_SQRT_RATIO = BigInt('1461446703485210103287273052203988822378723970342')

export const PERCENTAGE_FACTOR = BigInt(10)**BigInt(4);
export const HALF_PERCENTAGE_FACTOR = (BigInt(5)*BigInt(10)**BigInt(3));
export const SECONDS_PER_YEAR = BigInt(365 * 24 * 60 * 60);
export const PRECISION = (BigInt(10)**BigInt(27));//27
export const HALF_PRECISION = (BigInt(5)*BigInt(10)**BigInt(26));//27
export const RAY = (BigInt(10)**BigInt(27));//27
export const HALF_RAY = (BigInt(5)*BigInt(10)**BigInt(26));//27
export const WAD = (BigInt(10)**BigInt(18));
export const HALF_WAD = (BigInt(5)*BigInt(10)**BigInt(17));

export const MAX_UINT_AMOUNT =
  BigInt('115792089237316195423570985008687907853269984665640564039457584007913129639935');