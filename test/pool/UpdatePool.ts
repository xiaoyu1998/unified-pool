import { expect } from "chai";
import { deployContract } from "../../utils/deploy";
import { usdtDecimals } from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"
import { deployFixturePool } from "../../utils/fixture";

import { Position } from "../../typechain-types/contracts/test/PositionTest";

describe("Pool", () => {
    let fixture;
    let dataStore, poolStoreUtils, eventEmitter, poolToken, debtToken, poolTest;
    let user0, user1, user2;
    let usdt;

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
    });

    it("UpdatePool updateInterestRates", async () => {
       const supplyAmount = expandDecimals(1000000, usdtDecimals);
       const debtAmount = expandDecimals(500000, usdtDecimals);
       await usdt.transfer(poolToken, supplyAmount);
       await poolToken.mint(user0, supplyAmount, expandDecimals(1, 27));
       await debtToken.mint(user0, debtAmount, expandDecimals(1, 27));

       await poolTest.updatePool(eventEmitter, dataStore, usdt);
       const pool = await poolTest.getPool(dataStore, usdt);
       expect(pool.liquidityRate).eq("69444444444444444444444445");
       expect(pool.borrowRate).eq("208333333333333333333333334");
    });

}); 