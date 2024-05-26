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
import { testPoolConfiguration} from "../../utils/poolConfiguration";

describe("Exchange", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, router, exchangeRouter;
    let usdt, uni;
    let usdtPool, uniPool;

    beforeEach(async () => {
        fixture = await deployFixture();
        ({ 
            config, 
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

    it("executeDeposit", async () => {
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

    it("executeDeposit PoolNotFound", async () => {
        const usdtParams: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");
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