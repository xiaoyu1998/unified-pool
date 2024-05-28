import { expect } from "chai";
import { deployContract } from "../../utils/deploy";
import { usdtDecimals } from "../../utils/constants";
import { expandDecimals, bigNumberify, getRates} from "../../utils/math"
import { deployFixturePool } from "../../utils/fixture";
import { getRates } from "../../utils/pool";

import { Position } from "../../typechain-types/contracts/test/PositionTest";

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

    it("UpdatePool updateInterestRates borrowUsageRatio <= optimalUsageRation", async () => {
       const supplyAmount = expandDecimals(1000000, usdtDecimals);
       const debtAmount = expandDecimals(500000, usdtDecimals);
       await usdt.transfer(poolToken, supplyAmount);
       await poolToken.mint(user0, supplyAmount, expandDecimals(1, 27));
       await debtToken.mint(user0, debtAmount, expandDecimals(1, 27));
       await poolToken.addCollateral(user0, debtAmount);

       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool = await poolTest.getPool(dataStore, usdt);

       const { liquidityRate, borrowRate } = getRates(
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

    it("UpdatePool updateInterestRates borrowUsageRatio > optimalUsageRation", async () => {
       const supplyAmount = expandDecimals(1000000, usdtDecimals);
       const debtAmount = expandDecimals(900000, usdtDecimals);
       await usdt.transfer(poolToken, supplyAmount);
       await poolToken.mint(user0, supplyAmount, expandDecimals(1, 27));
       await debtToken.mint(user0, debtAmount, expandDecimals(1, 27));
       await poolToken.addCollateral(user0, debtAmount);

       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool = await poolTest.getPool(dataStore, usdt);

       const { liquidityRate, borrowRate } = getRates(
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

}); 