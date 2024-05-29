import { expect } from "chai";
import { deployContract } from "../../utils/deploy";
import { usdtDecimals, PRECISION } from "../../utils/constants";
import { expandDecimals, bigNumberify, calcRates, calcIndexes, calcFeeAmount, rayMul} from "../../utils/math"
import { deployFixturePool } from "../../utils/fixture";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Pool", () => {
    let fixture;
    let dataStore, poolStoreUtils, eventEmitter, poolToken, debtToken, poolTest;
    let user0, user1, user2;
    let usdt;
    let ratebase, optimalUsageRation, rateSlop1, rateSlop2, feeFactor;

    beforeEach(async () => {
        fixture = await deployFixturePool();
        ({  dataStore, 
            poolStoreUtils,
            eventEmitter,
            poolToken,
            debtToken,
            poolTest
         } = fixture.contracts); 
        ({ user0, user1, user2 } = fixture.accounts);
        ({ usdt } = fixture.assets);   
        ({ ratebase, optimalUsageRation, rateSlop1, rateSlop2, feeFactor } = fixture.rateFactors);    
    });
    
    it("UpdatePool updateInterestRates borrowUsageRatio > optimalUsageRation", async () => {
       const supplyAmount = expandDecimals(1000000, usdtDecimals);
       const debtAmount = expandDecimals(900000, usdtDecimals);
       await usdt.transfer(poolToken, supplyAmount);
       await poolToken.mint(user0, supplyAmount, expandDecimals(1, 27));
       await debtToken.mint(user0, debtAmount, expandDecimals(1, 27));
       await poolToken.addCollateral(user0, debtAmount);

       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool = await poolTest.getPool(dataStore, usdt);

       const { liquidityRate, borrowRate } = calcRates(
           ratebase,
           optimalUsageRation,
           rateSlop1,
           rateSlop2,
           supplyAmount - debtAmount,//should delete unclaimedFee
           debtAmount,
           feeFactor
       )
       expect(pool.liquidityRate).eq(liquidityRate);
       expect(pool.borrowRate).eq(borrowRate);
    });

    it("UpdatePool updateInterestRates borrowUsageRatio <= optimalUsageRation", async () => {
       const supplyAmount = expandDecimals(1000000, usdtDecimals);
       const debtAmount = expandDecimals(500000, usdtDecimals);
       await usdt.transfer(poolToken, supplyAmount);
       await poolToken.mint(user0, supplyAmount, expandDecimals(1, 27));
       await debtToken.mint(user0, debtAmount, expandDecimals(1, 27));
       await poolToken.addCollateral(user0, debtAmount);

       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool = await poolTest.getPool(dataStore, usdt);

       const { liquidityRate, borrowRate } = calcRates(
           ratebase,
           optimalUsageRation,
           rateSlop1,
           rateSlop2,
           supplyAmount - debtAmount,//should delete unclaimedFee
           debtAmount,
           feeFactor
       )

       expect(pool.liquidityRate).eq(liquidityRate);
       expect(pool.borrowRate).eq(borrowRate);
    });

    it("UpdatePool UpdateIndex, totalFee and unclaimedFee", async () => {
       const supplyAmount = expandDecimals(1000000, usdtDecimals);
       const debtAmount = expandDecimals(500000, usdtDecimals);
       await usdt.transfer(poolToken, supplyAmount);
       await poolToken.mint(user0, supplyAmount, expandDecimals(1, 27));
       await debtToken.mint(user0, debtAmount, expandDecimals(1, 27));
       await poolToken.addCollateral(user0, debtAmount);

       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool = await poolTest.getPool(dataStore, usdt);

       const interestPaymentPeriodInSeconds = BigInt(14 * 24 * 60 * 60);
       await time.increase(interestPaymentPeriodInSeconds);
       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool2 = await poolTest.getPool(dataStore, usdt);

       const {nextLiquidityIndex, nextBorrowIndex } = calcIndexes(
           pool.liquidityIndex, 
           pool.liquidityRate,
           pool.borrowIndex, 
           pool.borrowRate,
           interestPaymentPeriodInSeconds + bigNumberify(1)//TODO:why should add this one?
       );
       expect(pool2.liquidityIndex).eq(nextLiquidityIndex);
       expect(pool2.borrowIndex).eq(nextBorrowIndex);

       const feeAmount = calcFeeAmount(
           debtAmount,
           pool.borrowIndex,
           pool2.borrowIndex,
           pool2.liquidityIndex,
           feeFactor
       );
       expect(pool2.totalFee).eq(feeAmount);
       expect(pool2.unclaimedFee).eq(feeAmount);

       await time.increase(interestPaymentPeriodInSeconds);
       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool3 = await poolTest.getPool(dataStore, usdt);
       const { liquidityRate, borrowRate } = calcRates(
           ratebase,
           optimalUsageRation,
           rateSlop1,
           rateSlop2,
           supplyAmount - debtAmount - rayMul(feeAmount, pool3.borrowIndex),//should delete unclaimedFee
           rayMul(debtAmount, pool3.borrowIndex),
           feeFactor
       )

       expect(pool3.liquidityRate).eq(liquidityRate);
       expect(pool3.borrowRate).eq(borrowRate);

    });

}); 