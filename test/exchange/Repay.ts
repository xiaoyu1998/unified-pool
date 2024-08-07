import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, uniDecimals, usdtOracleDecimal, uniOracleDecimal} from "../../utils/constants";
import { errorsContract} from "../../utils/error";
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
    getBorrowApy,
    getHasDebt,
    getHasCollateral
} from "../../utils/helper"
import { DepositUtils } from "../../typechain-types/contracts/exchange/DepositHandler";
import { BorrowUtils } from "../typechain-types/contracts/exchange/BorrowHandler";
import { RepayUtils } from "../typechain-types/contracts/exchange/RepayHandler";
import { testPoolConfiguration} from "../../utils/pool";

describe("Exchange Repay", () => {
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

    it("executeRepay useCollateralToRepay noDebt hasCollateral", async () => {
        const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const usdtBorrowAmmount = expandDecimals(1000000, usdtDecimals);
        const usdtParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtBorrowAmmount,
        };
        const usdtAmountRepay = expandDecimals(1000000, usdtDecimals);
        const usdtParamsRepay: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmountRepay,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [usdtParamsRepay]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);
    
        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtDepositAmount + usdtBorrowAmmount - usdtAmountRepay);
        expect(await getDebt(dataStore, reader, user1.address, usdt.target)).eq(usdtBorrowAmmount - usdtAmountRepay);
        expect(await getHasDebt(dataStore, reader, user1.address, usdt.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, usdt.target)).eq(true);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0); 
    });

    it("executeRepay useCollateralToRepay noDebt noCollateral", async () => {
        const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };
        const uniAmountRepay = expandDecimals(100000, uniDecimals);
        const uniParamsRepay: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmountRepay,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);
    
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount - uniAmountRepay);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount - uniAmountRepay);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(expandDecimals(8, 27));
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(uniAmountRepay);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0); 
    });

    it("executeRepay useSendTokensToRepay hasDebt hasCollateral", async () => {
        const uniBalanceBeforePool = await uni.balanceOf(uniPool.poolToken);
        const uniBalanceBeforeUser1 = await uni.balanceOf(user1.address);

        const usdtAmountDeposit = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmountDeposit);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };

        const uniAmountRepay = expandDecimals(80000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniAmountRepay);
        const uniParamsRepay: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: 0,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmountRepay]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);
 
        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforePool + uniAmountRepay);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeUser1 - uniAmountRepay);   
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount - uniAmountRepay);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(true);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(true);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(expandDecimals(8, 27));
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(uniAmountRepay);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0); 
    });

    it("executeRepay useSendTokensToRepay noDebt hasCollateral hasOverpament", async () => {
        const uniBalanceBeforePool = await uni.balanceOf(uniPool.poolToken);
        const uniBalanceBeforeUser1 = await uni.balanceOf(user1.address);
        
        const usdtAmountDeposit = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmountDeposit);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };

        const uniAmountRepay = expandDecimals(120000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniAmountRepay);
        const uniParamsRepay: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: 0,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmountRepay]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);
 
        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforePool + uniBorrowAmmount);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeUser1 - uniBorrowAmmount);   
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(true);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(expandDecimals(8, 27));
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0); 
    });

    it("executeRepay EmptyPool", async () => {
        const uniAmountRepay = expandDecimals(400000, uniDecimals);
        const uniParamsRepay: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
            amount: uniAmountRepay,
        };
        const multicallArgsRepay = [
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsRepay)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPool");

    });

    it("executeRepay validateRepay", async () => {
        //EmptyPosition
        const usdtAmountDeposit = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmountDeposit);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const uniAmountRepay = expandDecimals(100000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniAmountRepay);
        const uniParamsRepay: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: 0,
        };       
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPosition");

        //UserDoNotHaveDebtInPool
        const uniAmountDeposit = expandDecimals(100000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniAmountDeposit);
        const uniParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: uni.target,
        };
        const multicallArgs2 = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs2)
        ).to.be.revertedWithCustomError(errorsContract, "UserDoNotHaveDebtInPool");

        //EmptyRepayAmount
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };
        const multicallArgs3 = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs3)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyRepayAmount");

        //InsufficientCollateralAmountForRepay
        const uniParamsRepay2: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: expandDecimals(100000, uniDecimals),
        }; 
        const uniAmountRedeem = expandDecimals(10000, uniDecimals);
        const uniParamsRedeem: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmountRedeem,
            to:user1.address
        };
        const multicallArgs4 = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [uniParamsRedeem]),
            exchangeRouter.interface.encodeFunctionData("executeRepay", [uniParamsRepay2]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs4)
        ).to.be.revertedWithCustomError(errorsContract, "InsufficientCollateralAmountForRepay");

    });

    it("executeRepay validateRepay testPoolConfiguration", async () => {
        const uniAmount = expandDecimals(400000, uniDecimals);
        const uniParams: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmount,
        };

        await testPoolConfiguration(config, exchangeRouter, user1, "executeRepay", uni, uniParams)
    });

}); 