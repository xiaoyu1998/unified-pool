import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { errorsContract} from "../../utils/error";
import { expandDecimals, bigNumberify, mulDiv, rayDiv } from "../../utils/math"
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
import { CloseUtils } from "../typechain-types/contracts/exchange/CloseHandler";
import { createAsset, createUniswapV3, addLiquidityV3 } from "../../utils/assetsDex";
import { testPoolConfiguration } from "../../utils/pool";
import { ethDecimals, ethOracleDecimals, PRECISION } from "../../utils/constants";

describe("Exchange ClosePosition", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, router, exchangeRouter, poolFactory, poolInterestRateStrategy;
    let usdt, uni;
    let usdtPool, uniPool;
    let usdtDecimals, usdtOracleDecimals, uniDecimals, uniOracleDecimals;
    let dex, poolV3;

    beforeEach(async () => {
        fixture = await deployFixture();
        ({  config, 
            dataStore, 
            roleStore, 
            reader,
            router,
            exchangeRouter,
            poolFactory,
            poolInterestRateStrategy
         } = fixture.contracts);
        ({ user0, user1, user2 } = fixture.accounts);
        ({ usdt, uni } = fixture.assets);
        ({ usdtPool, uniPool } = fixture.pools);
        ({  usdtDecimals, 
            usdtOracleDecimals,
            uniDecimals,
            uniOracleDecimals
         } = fixture.decimals);

        [dex, poolV3] = await createUniswapV3(
            roleStore,
            user0, 
            config, 
            usdt, 
            usdtDecimals, 
            uni, 
            uniDecimals, 
            8
        );

    });

    it("executeClosePosition debtAmount > 0 and swap", async () => {
        await addLiquidityV3(
            user0,
            usdt,
            uni,
            dex,
            poolV3
        )

        const uniDepositAmount = expandDecimals(100000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniDepositAmount);
        const uniParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: uni.target,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };
        const closePositionParams: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: uni.target,
            underlyingAssetUsd: usdt.target,
            percentage: expandDecimals(1, 27)//100%
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeClosePosition", [closePositionParams]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);

        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0); 

        // const colleratalUsdt = await getCollateral(dataStore, reader, user1.address, usdt.target);
        // console.log("colleratalUsdt", colleratalUsdt);
        //expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getDebt(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getHasDebt(dataStore, reader, user1.address, usdt.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, usdt.target)).eq(true);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0); 

    });

    it("executeClosePosition debtAmount > 0 and no swap", async () => {
        const usdtDepositAmount = expandDecimals(1000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };
        const closePositionParams: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: uni.target,
            underlyingAssetUsd: usdt.target,
            percentage: expandDecimals(1, 27)//100%
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeClosePosition", [closePositionParams]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);

        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0); 
    });

    it("executeClosePosition EmptyPool", async () => {
        //PoolIsNotUsd
        const closePositionParams: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
            underlyingAssetUsd: usdt.target,
            percentage: expandDecimals(1, 27)//100%
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeClosePosition", [closePositionParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPool"); 

        //PoolIsNotUsd
        const closePositionParams2: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: usdt.target,
            underlyingAssetUsd: ethers.ZeroAddress,
            percentage: expandDecimals(1, 27)//100%
        };
        const multicallArgs2 = [
            exchangeRouter.interface.encodeFunctionData("executeClosePosition", [closePositionParams2]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs2)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPool"); 
    });


    it("executeClosePosition PoolIsNotUsd", async () => {
        //PoolIsNotUsd
        const closePositionParams: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: uni.target,
            underlyingAssetUsd: uni.target,
            percentage: expandDecimals(1, 27)//100%
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeClosePosition", [closePositionParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "PoolIsNotUsd"); 
    });

    it("executeClosePosition validateClosePosition EmptyPosition", async () => {
        //EmptyPosition
        const closePositionParams: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: uni.target,
            underlyingAssetUsd: usdt.target,
            percentage: expandDecimals(1, 27)//100%
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeClosePosition", [closePositionParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "EmptyPosition"); 
    });


    it("executeClosePosition validateClosePosition CollateralCanNotCoverDebt and underlyingAsset testPoolConfiguration", async () => {
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
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);


        const closePositionParams: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: uni.target,
            underlyingAssetUsd: usdt.target,
            percentage: expandDecimals(1, 27)//100%
        };
        const multicallArgs2 = [
            exchangeRouter.interface.encodeFunctionData("executeClosePosition", [closePositionParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs2)
        ).to.be.revertedWithCustomError(errorsContract, "CollateralCanNotCoverDebt");         

        await testPoolConfiguration(config, exchangeRouter, user1, "executeClosePosition", uni, closePositionParams)
    });

    it("executeClosePosition validateClosePosition underlyingAssetUsd testPoolConfiguration", async () => {
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
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);


        const closePositionParams: CloseUtils.ClosePositionParamsStructOutput = {
            underlyingAsset: uni.target,
            underlyingAssetUsd: usdt.target,
            percentage: expandDecimals(1, 27)//100%
        };       

        await testPoolConfiguration(config, exchangeRouter, user1, "executeClosePosition", usdt, closePositionParams)
    });


}); 