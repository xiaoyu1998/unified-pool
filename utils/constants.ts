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
export const usdtOracleDecimal = 24;
export const uniDecimals = 18;
export const uniOracleDecimal = 12;

export const MIN_SQRT_RATIO = BigInt('4295128739')
export const MAX_SQRT_RATIO = BigInt('1461446703485210103287273052203988822378723970342')

export const PERCENTAGE_FACTOR = BigInt(10000);
export const HALF_PERCENTAGE_FACTOR = BigInt(5000);