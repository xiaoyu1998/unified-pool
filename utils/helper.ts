
const { getContract } = require("./deploy")
import { Pool } from "../typechain-types/contracts/pool/PoolFactory";
import { Position } from "../typechain-types/contracts/position/PositionStoreUtils";
// import { ReaderUtils } from "../typechain-types/contracts/reader/ReaderUtils";
import { ReaderUtils } from "../typechain-types/contracts/reader/Reader";

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
        // feeFactor: pool[10],
        totalFee: pool[10],
        unclaimedFee: pool[11],
        lastUpdateTimestamp: pool[12]
    };
    return p;
}

export async function getPool(address) {
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const poolUsdt = await reader.getPool(dataStore.target, address);
    return parsePool(poolUsdt);
}

export function parsePoolInfo(pool) {
    const p: ReaderUtils.GetPoolInfoStruct = {
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
        totalFee: pool[10],
        unclaimedFee: pool[11],
        lastUpdateTimestamp: pool[12],
        isActive: pool[13],
        isPaused: pool[14],
        isFrozen: pool[15],
        borrowingEnabled: pool[16],
        decimals: pool[17],
        feeFactor: pool[18],
        symbol: pool[19],
        price: pool[20]
    };
    return p;
}

export async function getPoolInfo(address) {
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const poolUsdt = await reader.getPoolInfo(dataStore.target, address);
    return parsePoolInfo(poolUsdt);
}

export function parsePosition(position) {
    const p: Position.PropsStruct = {
        underlyingAsset: position[0],
        account: position[1],
        entryLongPrice: position[2],
        accLongAmount: position[3],
        entryShortPrice: position[4],
        accShortAmount: position[5],
        isLong: position[6],
        hasCollateral: position[7],
        hasDebt: position[8]
    };
    return p;
}

export async function getPositions(dataStore, reader, address) {
    const positions = await reader.getPositions(dataStore.target, address);
    let ps = [];
    for (let i = 0; i < positions.length; i++) {
         ps[i] = parsePosition(positions[i]);
    }
    return ps;
}

export function parseAccountLiquidityAndDebt(liquidity) {
    const l: ReaderUtils.AccountLiquidityAndDebtStruct = {
        underlyingAsset: liquidity[0],
        account: liquidity[1],
        balance: liquidity[2],
        scaled: liquidity[3],
        collateral: liquidity[4],
        scaledDebt: liquidity[5],
        debt: liquidity[6],
    };
    return l;
}

export async function getAccountLiquidityAndDebtInPools(dataStore, reader, address) {
    const liquidities = await reader.getAccountLiquidityAndDebtInPools(dataStore.target, address);
    const accountLiquidities = [];
    for (let i = 0; i < liquidities.length; i++) {
         accountLiquidities[i] = parseAccountLiquidityAndDebt(liquidities[i]);
    }
    return accountLiquidities;    
}

export function parsePoolLiquidityAndDebt(liquidity) {
    const l: ReaderUtils.PoolLiquidityAndDebtStruct = {
        underlyingAsset: liquidity[0],
        scaledTotalSupply: liquidity[1],
        totalSupply: liquidity[2],
        totalCollateral: liquidity[3],
        availableLiquidity: liquidity[4],
        scaledTotalDebt: liquidity[5],
        totalDebt: liquidity[6],
    };
    return l;
}

export async function getPoolsLiquidityAndDebt(dataStore, reader) {
    const liquidities = await reader.getPoolsLiquidityAndDebt(dataStore.target);
    const poolsLiquidities = [];
    for (let i = 0; i < liquidities.length; i++) {
         poolsLiquidities[i] = parsePoolLiquidityAndDebt(liquidities[i]);
    }
    return poolsLiquidities;    
}

// export type LiquidityPropsStruct = {
//     underlyingAsset: AddressLike;
//     scaledTotalSupply: BigNumberish;
//     totalSupply: BigNumberish;
//     totalCollateral: BigNumberish;
//     availableLiquidity: BigNumberish;

//     account: AddressLike;
//     balance: BigNumberish;
//     scaled: BigNumberish;
//     collateral: BigNumberish;
// };

// export async function getLiquidity(poolToken, address) {
//     const l: LiquidityPropsStruct = {
//         underlyingAsset: await poolToken.underlyingAsset(),
//         scaledTotalSupply: await poolToken.scaledTotalSupply(),
//         totalSupply:await poolToken.totalSupply(),
//         totalCollateral: await poolToken.totalCollateral(),
//         availableLiquidity: await poolToken.availableLiquidity()
//     };

//     if (address) {
//         l.account = address;
//         l.balance = await poolToken.balanceOf(address);
//         l.scaled  = await poolToken.scaledBalanceOf(address);
//         l.collateral = await poolToken.balanceOfCollateral(address);
//     }

//     return l;
// }

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
        l.scaledDebt = await debtToken.scaledBalanceOf(address);
        l.debt  = await debtToken.balanceOf(address);
    }

    return l;
}


