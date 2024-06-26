import { expect } from "chai";
import { deployContract } from "../../utils/deploy";
import { usdtDecimals, usdtOracleDecimals} from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"

import { Position } from "../../typechain-types/contracts/test/PositionTest";

describe("Position ShortPosition", () => {
    let positionTest;

    beforeEach(async () => {
        positionTest = await deployContract("PositionTest", []);
    });

    it("shortPosition none to short", async () => {
        let price = expandDecimals(8, usdtOracleDecimals);
        let amount = expandDecimals(1, usdtDecimals);
        const position: Position.PropsStructOutput = {
            account: ethers.ZeroAddress,
            underlyingAsset: ethers.ZeroAddress,
            entryLongPrice: 0,
            accLongAmount: 0,
            entryShortPrice: 0,
            accShortAmount: 0,
            positionType: 2,
            hasCollateral: true,
            hasDebt: true,
        };
        let positionOutput = await positionTest.shortPosition(position, price, amount, false);

        expect(positionOutput.positionType).eq(0);
        expect(positionOutput.entryShortPrice).eq(price);
        expect(positionOutput.accShortAmount).eq(amount);
    });

    it("shortPosition short to short, New price accumulate to the entry price", async () => {
        let price = expandDecimals(8, usdtOracleDecimals);
        let amount = expandDecimals(1, usdtDecimals);
        const position: Position.PropsStructOutput = {
            account: ethers.ZeroAddress,
            underlyingAsset: ethers.ZeroAddress,
            entryLongPrice: 0,
            accLongAmount: 0,
            entryShortPrice: price,
            accShortAmount: amount,
            positionType: 0,
            hasCollateral: true,
            hasDebt: true,
        };

        const newPrice = bigNumberify(2) * price;
        let positionOutput = await positionTest.shortPosition(position, newPrice, amount, true);
        expect(positionOutput.positionType).eq(0);
        expect(positionOutput.entryShortPrice).eq((price*amount + newPrice*amount)/(amount + amount));
        expect(positionOutput.accShortAmount).eq(amount + amount);
    });

    it("shortPosition short to short, New price don't accumulate to the entry price", async () => {
        let price = expandDecimals(8, usdtOracleDecimals);
        let amount = expandDecimals(1, usdtDecimals);
        const position: Position.PropsStructOutput = {
            account: ethers.ZeroAddress,
            underlyingAsset: ethers.ZeroAddress,
            entryLongPrice: 0,
            accLongAmount: 0,
            entryShortPrice: price,
            accShortAmount: amount,
            positionType: 0,
            hasCollateral: true,
            hasDebt: true,
        };

        const newPrice = bigNumberify(2) * price;
        let positionOutput = await positionTest.shortPosition(position, newPrice, amount, false);
        expect(positionOutput.positionType).eq(0);
        expect(positionOutput.entryShortPrice).eq(price);
        expect(positionOutput.accShortAmount).eq(amount + amount);
    });

    it("shortPosition long to short, accShortAmount > amount", async () => {
        let price = expandDecimals(8, usdtOracleDecimals);
        let amount = expandDecimals(2, usdtDecimals);
        const position: Position.PropsStructOutput = {
            account: ethers.ZeroAddress,
            underlyingAsset: ethers.ZeroAddress,
            entryLongPrice: price,
            accLongAmount: amount,
            entryShortPrice: 0,
            accShortAmount: 0,
            positionType: 1,
            hasCollateral: true,
            hasDebt: true,
        };

        let newAmount = amount/bigNumberify(2);
        let positionOutput = await positionTest.shortPosition(position, price, newAmount, false);
        expect(positionOutput.positionType).eq(1);
        expect(positionOutput.entryLongPrice).eq(price);
        expect(positionOutput.accLongAmount).eq(amount - newAmount);
    });

    it("shortPosition long to short, accShortAmount < amount", async () => {
        let price = expandDecimals(8, usdtOracleDecimals);
        let amount = expandDecimals(1, usdtDecimals);
        const position: Position.PropsStructOutput = {
            account: ethers.ZeroAddress,
            underlyingAsset: ethers.ZeroAddress,
            entryLongPrice: price,
            accLongAmount: amount,
            entryShortPrice: 0,
            accShortAmount: 0,
            positionType: 1,
            hasCollateral: true,
            hasDebt: true,
        };

        let newAmount = amount*bigNumberify(2);
        let positionOutput = await positionTest.shortPosition(position, price, newAmount, false);
        expect(positionOutput.positionType).eq(0);
        expect(positionOutput.entryLongPrice).eq(0);
        expect(positionOutput.accLongAmount).eq(0);
        expect(positionOutput.entryShortPrice).eq(price);
        expect(positionOutput.accShortAmount).eq(newAmount - amount);
    });


}); 