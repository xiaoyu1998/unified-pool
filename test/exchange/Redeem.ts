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
    getBorrowApy
} from "../../utils/helper"
import { DepositUtils } from "../../typechain-types/contracts/exchange/DepositHandler";
import { WithdrawUtils } from "../typechain-types/contracts/exchange/WithdrawHandler";
import { RedeemUtils } from "../typechain-types/contracts/exchange/RedeemHandler";
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

    it("executeRedeem redeemAmount <= maxAmountToRedeem", async () => {
        //Deposit
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
        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);

        const usdtBalanceBeforeRedeemPool = await usdt.balanceOf(usdtPool.poolToken);
        const usdtBalanceBeforeRedeemUser1 = await usdt.balanceOf(user1.address);
        const usdtAmountRedeem = expandDecimals(1000000, usdtDecimals);
        const usdtParamsRedeem: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmountRedeem,
            to:user1.address
        };

        const multicallArgsRedeem = [
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [usdtParamsRedeem]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsRedeem);
    
        //redeemAmount <= collateralAmount
        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforeRedeemPool - usdtAmountRedeem);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeRedeemUser1 + usdtAmountRedeem);
        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtDepositAmount + usdtBorrowAmmount - usdtAmountRedeem);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0); 
    });

    it("executeRedeem redeemAmount > maxAmountToRedeem", async () => {
        const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const uniDepositAmount = expandDecimals(200000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniDepositAmount);
        const uniParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: uni.target,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };
        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);
        const uniBalanceBeforeRedeemPool = await uni.balanceOf(uniPool.poolToken);
        const uniBalanceBeforeRedeemUser1 = await uni.balanceOf(user1.address);
        const uniCollateralBeforeBorrowUser1 = uniDepositAmount + uniBorrowAmmount;

        //Redeem
        const uniAmountRedeem = expandDecimals(400000, uniDecimals);
        const uniParamsRedeem: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmountRedeem,
            to:user1.address
        };

        const multicallArgsRedeem = [
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [uniParamsRedeem]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsRedeem);
    
        //redeemAmount > collateralAmount
        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforeRedeemPool - uniCollateralBeforeBorrowUser1);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeRedeemUser1 + uniCollateralBeforeBorrowUser1);
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(0);
        //shortPosition Long to Short
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(expandDecimals(8, 27));
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount);
    });

    it("executeRedeem PoolNotFound", async () => {
        const uniAmountRedeem = expandDecimals(400000, uniDecimals);
        const uniParamsRedeem: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
            amount: uniAmountRedeem,
            to: user1.address
        };
        const multicallArgsRedeem = [
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [uniParamsRedeem]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsRedeem)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

    });

    it("executeRedeem validateRedeem", async () => {

        //EmptyPosition
        const uniAmountRedeem = expandDecimals(400000, uniDecimals);
        const uniParamsRedeem: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmountRedeem,
            to:user1.address
        };
        const multicallArgsRedeem = [
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [uniParamsRedeem]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsRedeem)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPosition");

        //EmptyRedeemAmount
        const uniDepositAmount = expandDecimals(200000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniDepositAmount);
        const uniParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: uni.target,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };
        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);

        const uniAmountRedeem2 = expandDecimals(0, uniDecimals);
        const uniParamsRedeem2: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmountRedeem2,
            to:user1.address
        };
        const multicallArgsRedeem2 = [
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [uniParamsRedeem2]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsRedeem2)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyRedeemAmount");

        //HealthFactorLowerThanLiquidationThreshold
        const uniAmountRedeem3 = expandDecimals(100000, uniDecimals);
        const uniParamsRedeem3: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmountRedeem3,
            to:user1.address
        };

        const multicallArgsConfig = [
            config.interface.encodeFunctionData("setHealthFactorLiquidationThreshold", [expandDecimals(21, 26)]),//210%
            config.interface.encodeFunctionData("setDebtMultiplierFactorForRedeem", [expandDecimals(110, 25)]),//110%
        ];
        await config.multicall(multicallArgsConfig);

        const multicallArgsRedeem3 = [
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [uniParamsRedeem3]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsRedeem3)
        ).to.be.revertedWithCustomError(errorsContract, "HealthFactorLowerThanLiquidationThreshold");        
    
    });

    it("executeRedeem validateRedeem poolConfiguration", async () => {

        const uniAmount = expandDecimals(400000, uniDecimals);
        const uniParams: RedeemUtils.RedeemParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmount,
            to:user1.address
        };

        await testPoolConfiguration(config, exchangeRouter, user1, "executeSupply", uni, uniParams)
 
    });

}); 