import { expect } from "chai";
import { usdtDecimals, PRECISION } from "../../utils/constants";
import { expandDecimals, bigNumberify, calcRates, calcIndexes, calcFeeAmount, rayMul} from "../../utils/math"
import { deployFixturePool } from "../../utils/fixture";
import { errorsContract} from "../../utils/error";

describe("poolToken Modifiers", () => {
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
    });
    
    it("poolToken to invoke mint not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            poolToken.connect(user1).mint(user0, amount, expandDecimals(1, 27))
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("poolToken to invoke burn not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            poolToken.connect(user1).burn(user1, user1, amount, expandDecimals(1, 27), 0)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("poolToken to invoke transferOnLiquidation not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            poolToken.connect(user1).transferOnLiquidation(user1, user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("poolToken to invoke transferOutUnderlyingAsset not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            poolToken.connect(user1).transferOutUnderlyingAsset(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("poolToken to invoke addCollateral not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            poolToken.connect(user1).addCollateral(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("poolToken to invoke removeCollateral not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            poolToken.connect(user1).removeCollateral(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("poolToken to invoke approveLiquidity not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            poolToken.connect(user1).approveLiquidity(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

}); 