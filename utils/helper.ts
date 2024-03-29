
const { getContract } = require("./deploy")
import { Pool } from "../typechain-types/contracts/pool/PoolFactory";

export function parsePool(pool) {
    const p: Pool.PropsStruct = {
        keyId: pool[0],
        liquidityIndex: pool[1],
        liquidityRate: pool[2],
        borrowIndex: pool[3],
        borrowRate: pool[4],
        interestRateStrategy: pool[5],
        underlyingAsset: pool[6],
        poolToken: pool[7],
        debtToken: pool[8],
        configuration: pool[9],
        feeFactor: pool[10],
        totalFee: pool[11],
        unclaimedFee: pool[12],
        lastUpdateTimestamp: pool[13]
    };
    return p;
}

export async function getPool(address) {
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const poolUsdt = await reader.getPool(dataStore.target, address);
    return parsePool(poolUsdt);
}

export type LiquidityPropsStruct = {
    underlyingAsset: AddressLike;
    scaledTotalSupply: BigNumberish;
    totalSupply: BigNumberish;
    totalCollateral: BigNumberish;
    availableLiquidity: BigNumberish;

    account: AddressLike;
    balance: BigNumberish;
    scaled: BigNumberish;
    collateral: BigNumberish;
};

export async function getLiquidity(poolToken, address) {
    const l: LiquidityPropsStruct = {
        underlyingAsset: await poolToken.underlyingAsset(),
        scaledTotalSupply: await poolToken.scaledTotalSupply(),
        totalSupply:await poolToken.totalSupply(),
        totalCollateral: await poolToken.totalCollateral(),
        availableLiquidity: await poolToken.totalUnderlyingAssetBalanceSubTotalCollateral()
    };

    if (address) {
        l.account = address;
        l.balance = await poolToken.balanceOf(address);
        l.scaled  = await poolToken.scaledBalanceOf(address);
        l.collateral = await poolToken.balanceOfCollateral(address);
    }

    return l;
}

export type DebtPropsStruct = {
    underlyingAsset: AddressLike;
    scaledTotalDebt: BigNumberish;
    totalDebt: BigNumberish;

    account: AddressLike;
    scaledDebt: BigNumberish;
    debt: BigNumberish;
};

export async function getDebt(debtToken, address) {
    const l: DebtPropsStruct = {
        underlyingAsset: await debtToken.underlyingAsset(),
        scaledTotalDebt: await debtToken.scaledTotalSupply(),
        totalDebt:await debtToken.totalSupply(),
    };

    if (address) {
        l.account = address;
        l.scaledDebt = await debtToken.balanceOf(address);
        l.debt  = await debtToken.scaledBalanceOf(address);
    }

    return l;
}


