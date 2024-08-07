import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, uniDecimals} from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"
import { getSupply } from "../../utils/helper"
import { WithdrawUtils } from "../typechain-types/contracts/exchange/WithdrawHandler";
import { errorsContract} from "../../utils/error";
import { testPoolConfiguration} from "../../utils/pool";

describe("Exchange Withdraw", () => {
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

    it("executeWithdraw AmountToWithdraw <= UserSupplyBalance", async () => {
        const usdtBalanceBeforePool = await usdt.balanceOf(usdtPool.poolToken);
        const usdtBalanceBeforeUser1 = await usdt.balanceOf(user0.address);
        const usdtSupplyBeforeUser1 = await getSupply(dataStore, reader, user0.address, usdt.target);

        const usdtAmount = expandDecimals(2000000, usdtDecimals);
        const usdtParams: WithdrawUtils.WithdrawParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmount,
            to: user0.address,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeWithdraw", [usdtParams]),
        ];
        await exchangeRouter.connect(user0).multicall(multicallArgs);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforePool - usdtAmount);
        expect(await usdt.balanceOf(user0.address)).eq(usdtBalanceBeforeUser1 + usdtAmount);
        expect(await getSupply(dataStore, reader, user0.address, usdt.target)).eq(usdtSupplyBeforeUser1 - usdtAmount);
    });

    it("executeWithdraw AmountToWithdraw > UserSupplyBalance", async () => {
        const usdtBalanceBeforePool = await usdt.balanceOf(usdtPool.poolToken);
        const usdtBalanceBeforeUser1 = await usdt.balanceOf(user0.address);
        //const usdtSupplyBeforeUser1 = await getSupply(dataStore, reader, user0.address, usdt.target);

        const usdtAmount = expandDecimals(11000000, usdtDecimals);
        const usdtParams: WithdrawUtils.WithdrawParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmount,
            to: user0.address,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeWithdraw", [usdtParams]),
        ];
        await exchangeRouter.connect(user0).multicall(multicallArgs);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(0);
        expect(await usdt.balanceOf(user0.address)).eq(usdtBalanceBeforeUser1 + usdtBalanceBeforePool);
        expect(await getSupply(dataStore, reader, user0.address, usdt.target)).eq(0);
    });

    it("executeWithdraw AmountToWithdraw > availableLiquidity", async () => {
        const usdtBalanceBeforePool = await usdt.balanceOf(usdtPool.poolToken);
        const uniAmountDeposit = expandDecimals(200000, uniDecimals);
        await uni.connect(user0).approve(router.target, uniAmountDeposit);
        const uniParamsDeposit: DepositUtils.DepositParamsStruct = {
            underlyingAsset: uni.target,
        };
        const usdtAmmountBorrow = expandDecimals(1000000, usdtDecimals);
        const usdtParamsBorrow: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: usdt.target,
            amount: usdtAmmountBorrow,
        };
        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
        ];
        await exchangeRouter.connect(user0).multicall(multicallArgsDeposit);

        const usdtBalanceBeforeUser1 = await usdt.balanceOf(user0.address);
        const usdtAmount1 = expandDecimals(10000000, usdtDecimals);
        const usdtParams1: WithdrawUtils.WithdrawParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmount1,
            to: user0.address,
        };
        const multicallArgs2 = [
            exchangeRouter.interface.encodeFunctionData("executeWithdraw", [usdtParams1]),
        ];
        await exchangeRouter.connect(user0).multicall(multicallArgs2);
        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtAmmountBorrow);
        expect(await usdt.balanceOf(user0.address)).eq(usdtBalanceBeforeUser1 + usdtBalanceBeforePool - usdtAmmountBorrow);
        expect(await getSupply(dataStore, reader, user0.address, usdt.target)).eq("1000000001980");

    });

    it("executeWithdraw EmptyPool", async () => {
        const usdtAmount = expandDecimals(2000000, usdtDecimals);
        const usdtParams: WithdrawUtils.WithdrawParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
            amount: usdtAmount,
            to: user0.address,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeWithdraw", [usdtParams]),
        ];
        await expect(
            exchangeRouter.connect(user0).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPool");
    });

    it("executeWithdraw validateWithdraw", async () => {
        //EmptyWithdrawAmounts
        const usdtAmount = expandDecimals(0, usdtDecimals);
        const usdtParams: WithdrawUtils.WithdrawParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmount,
            to: user0.address,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeWithdraw", [usdtParams]),
        ];
        await expect(
            exchangeRouter.connect(user0).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyWithdrawAmounts");   
    });    

    it("executeWithdraw validateWithdraw poolConfiguration", async () => {
        const usdtAmount = expandDecimals(2000000, usdtDecimals);
        const usdtParams: WithdrawUtils.WithdrawParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmount,
            to: user0.address,
        };
        await testPoolConfiguration(config, exchangeRouter, user0, "executeWithdraw", usdt, usdtParams)
    });

}); 