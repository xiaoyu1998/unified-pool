import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, uniDecimals, usdtOracleDecimal, uniOracleDecimal} from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"
import { 
    getCollateral, 
    getPositionType, 
    getEntryLongPrice, 
    getAccLongAmount, 
    getEntryShortPrice, 
    getAccShortAmount,
    getDebt,
    getSupplyApy,
    getBorrowApy
} from "../../utils/helper"
import { DepositUtils } from "../../typechain-types/contracts/exchange/DepositHandler";
import { errorsContract} from "../../utils/error";
import { testPoolConfiguration} from "../../utils/pool";

describe("Exchange Deposit", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, router, exchangeRouter;
    let usdt, uni;
    let usdtPool, uniPool;

    beforeEach(async () => {
        fixture = await deployFixture();
        ({  config, 
            dataStore, 
            roleStore, 
            reader,
            router,
            exchangeRouter
         } = fixture.contracts);
        ({ user0, user1, user2 } = fixture.accounts);
        ({ usdt, uni } = fixture.assets);
        ({ usdtPool, uniPool } = fixture.pools);
    });

    it("executeDeposit usd", async () => {
        const usdtBalanceBeforePool = await usdt.balanceOf(usdtPool.poolToken);
        const usdtBalanceBeforeUser1 = await usdt.balanceOf(user1.address);

        //Deposit
        const usdtAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmount);
        const usdtParams: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParams]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforePool + usdtAmount);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeUser1 - usdtAmount);
        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtAmount);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0);  
    });

    it("executeDeposit longPosition none to long", async () => {
        const uniBalanceBeforePool = await uni.balanceOf(uniPool.poolToken);
        const uniBalanceBeforeUser1 = await uni.balanceOf(user1.address);

        //Deposit
        const uniAmount = expandDecimals(200000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniAmount);
        const usdtParams: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const uniParams: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: uni.target,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParams]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);

        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforePool + uniAmount);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeUser1 - uniAmount);
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniAmount);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(expandDecimals(8, 27));
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(uniAmount);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0);
    }); 

    it("executeDeposit EmptyPool", async () => {
        const usdtParams: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPool");
    });

    it("executeDeposit validateWithdraw", async () => {
        //EmptyDepositAmounts
        const usdtParams: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyDepositAmounts");
    });

    it("executeDeposit validateWithdraw testPoolConfiguration", async () => {
        const usdtAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmount);
        const usdtParams: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParams]),
        ];
        await testPoolConfiguration(config, exchangeRouter, user1, "executeDeposit", usdt, usdtParams)
    });

}); 