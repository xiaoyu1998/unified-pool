import { expect } from "chai";
import { usdtDecimals, PRECISION } from "../../utils/constants";
import { expandDecimals, bigNumberify, calcRates, calcIndexes, calcFeeAmount, rayMul} from "../../utils/math"
import { deployFixturePool } from "../../utils/fixture";
import { errorsContract} from "../../utils/error";

describe("debtToken Modifiers", () => {
    let fixture;
    let dataStore, poolStoreUtils, eventEmitter, poolToken, debtToken, poolTest;
    let user0, user1, user2;
    let usdt;
    let ratebase, optimalUsageRation, rateSlop1, rateSlop2, feeFactor;

    beforeEach(async () => {
        fixture = await deployFixturePool();
        ({  debtToken
         } = fixture.contracts); 
        ({ user0, user1, user2 } = fixture.accounts);
        ({ usdt } = fixture.assets);      
    });
    
    it("debtToken to invoke mint not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).mint(user0, amount, expandDecimals(1, 27))
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("debtToken to invoke burn not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).burn(user1, amount, expandDecimals(1, 27))
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("debtToken to invoke burnAll not being the controller", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).burnAll(user1)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
    });

    it("debtToken to invoke transfer not to be supported", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).transfer(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "DebtTokenOperationNotSupported");
    });

    it("debtToken to invoke allowance not to be supported", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).allowance(user1, user2)
        ).to.be.revertedWithCustomError(errorsContract, "DebtTokenOperationNotSupported");
    });

    it("debtToken to invoke approve not to be supported", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).approve(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "DebtTokenOperationNotSupported");
    });

    it("debtToken to invoke transferFrom not to be supported", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).transferFrom(user1, user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "DebtTokenOperationNotSupported");
    });

    it("debtToken to invoke increaseAllowance not to be supported", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).increaseAllowance(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "DebtTokenOperationNotSupported");
    });

    it("debtToken to invoke decreaseAllowance not to be supported", async () => {
       const amount = expandDecimals(1, usdtDecimals);
        await expect(
            debtToken.connect(user1).decreaseAllowance(user1, amount)
        ).to.be.revertedWithCustomError(errorsContract, "DebtTokenOperationNotSupported");
    });

}); 