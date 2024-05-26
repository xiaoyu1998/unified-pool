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
import { BorrowUtils } from "../typechain-types/contracts/exchange/BorrowHandler";
import { errorsContract} from "../../utils/error";
import { testPoolConfiguration} from "../../utils/poolConfiguration";

describe("Exchange", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, router, exchangeRouter;
    let usdt, uni;
    let usdtPool, uniPool;
    let usdtBalanceUser1, uniBalanceUser1, usdtSupplyAmount, uniSupplyAmount;

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
        ({ usdtBalanceUser1, uniBalanceUser1, usdtSupplyAmount, uniSupplyAmount} = fixture.balances);
    });

    it("executeBorrow borrowUsageRatio < OPTIMAL_USAGE_RATIO", async () => {
        //Deposit
        const usdtAmountDeposit = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmountDeposit);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);

        //borrow 
        const usdtCollateralBeforeBorrowUser1 = await getCollateral(dataStore, reader, user1.address, usdt.target);
        const usdtAmmountBorrow = expandDecimals(1000000, usdtDecimals);
        const usdtParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmmountBorrow,
        };
        const multicallArgsBorrow = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsBorrow);

        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtCollateralBeforeBorrowUser1 + usdtAmmountBorrow);
        expect(await getDebt(dataStore, reader, user1.address, usdt.target)).eq(usdtAmmountBorrow);
        expect(await getSupplyApy(dataStore, reader, user1.address, usdt.target)).eq("6243750000000000000000000");
        expect(await getBorrowApy(dataStore, reader, user1.address, usdt.target)).eq("62500000000000000000000000");

    });

    it("executeBorrow borrowUsageRatio >= OPTIMAL_USAGE_RATIO", async () => {
        //Deposit
        const usdtAmountDeposit = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmountDeposit);
        const uniAmountDeposit = expandDecimals(200000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniAmountDeposit);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const uniParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: uni.target,
        };

        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);

        //borrow 
        const uniCollateralBeforeBorrowUser1 = await getCollateral(dataStore, reader, user1.address, uni.target);
        const uniAmmountBorrow = expandDecimals(900000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmmountBorrow,
        };
        const multicallArgsBorrow = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsBorrow);

        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniCollateralBeforeBorrowUser1 + uniAmmountBorrow);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(uniAmmountBorrow);
        expect(await getSupplyApy(dataStore, reader, user1.address, uni.target)).eq("674325000000000000000000000");
        expect(await getBorrowApy(dataStore, reader, user1.address, uni.target)).eq("750000000000000000000000000");

    });

    it("executeBorrow PoolNotFound", async () => {
        const usdtAmmount = expandDecimals(1000000, usdtDecimals);
        const usdtParams: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
            amount: usdtAmmount,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");
    });

    it("executeBorrow validateWithdraw", async () => {
        //EmptyBorrowAmounts
        const usdtAmmount = expandDecimals(0, usdtDecimals);
        const usdtParams: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmmount,
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyBorrowAmounts");

        //InsufficientLiquidityForBorrow
        const usdtAmountDeposit = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmountDeposit);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);

        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniSupplyAmount+bigNumberify(1),
        };
        const multicallArgsBorrow = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsBorrow)
        ).to.be.revertedWithCustomError(errorsContract, "InsufficientLiquidityForBorrow");

        //BorrowCapacityExceeded
        const multicallArgsConfig = [
            config.interface.encodeFunctionData("setPoolBorrowCapacity", [uni.target, expandDecimals(1, 5)]),//100,000,000
        ];
        await config.multicall(multicallArgsConfig);
        const uniParamsBorrow2: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniSupplyAmount-bigNumberify(1),
        };
        const multicallArgsBorrow2 = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow2]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsBorrow2)
        ).to.be.revertedWithCustomError(errorsContract, "BorrowCapacityExceeded");

        //HealthFactorLowerThanLiquidationThreshold
         const multicallArgsConfig2 = [
            config.interface.encodeFunctionData("setHealthFactorLiquidationThreshold", [expandDecimals(3, 27)]),//300%
        ];
        await config.multicall(multicallArgsConfig2);
        const usdtParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmountDeposit,
        };
        const multicallArgsBorrow3 = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsBorrow3)
        ).to.be.revertedWithCustomError(errorsContract, "HealthFactorLowerThanLiquidationThreshold");       

    });



    it("executeBorrow validateWithdraw testPoolConfiguration", async () => {
        //EmptyBorrowAmounts
        const usdtAmmount = expandDecimals(1000000, usdtDecimals);
        const usdtParams: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: usdt.target,
            amount: usdtAmmount,
        };
        await testPoolConfiguration(config, exchangeRouter, user1, "executeBorrow", usdt, usdtParams)

    });


}); 