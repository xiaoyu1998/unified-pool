export const MaxUint128 = BigInt(2)**BigInt(128) - BigInt(1);
export const MaxUint256 = BigInt(2)**BigInt(256) - BigInt(1);

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

export const WS_URL = "ws://127.0.0.1:8545";
