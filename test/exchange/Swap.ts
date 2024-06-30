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
import { SwapUtils } from "../typechain-types/contracts/exchange/SwapHandler";
import { createAsset, createUniswapV3, addLiquidityV3 } from "../../utils/assetsDex";
import { testPoolConfiguration } from "../../utils/pool";
import { ethDecimals, ethOracleDecimals, PRECISION } from "../../utils/constants";

describe("Exchange Swap", () => {
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
            user0, 
            config, 
            usdt, 
            usdtDecimals, 
            uni, 
            uniDecimals, 
            8
        );

    });

    it("executeSwap InsufficientDexLiquidity", async () => {
        const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const usdtAmountSwap = expandDecimals(1000000, usdtDecimals);
        const usdtParamsSwap: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: usdt.target,
            underlyingAssetOut: uni.target,
            amount: usdtAmountSwap,
            sqrtPriceLimitX96: 0

        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeSwap", [usdtParamsSwap]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "InsufficientDexLiquidity");
    
    });

    it("executeSwap long amountIn < collateralAmount", async () => {
        await addLiquidityV3(
            user0,
            usdt,
            uni,
            dex,
            poolV3
        )

        const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const usdtAmountIn = expandDecimals(1000000, usdtDecimals);
        const usdtParamsSwap: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: usdt.target,
            underlyingAssetOut: uni.target,
            amount: usdtAmountIn,
            sqrtPriceLimitX96: 0
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeSwap", [usdtParamsSwap]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);
    
        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtDepositAmount - usdtAmountIn);
        expect(await getHasDebt(dataStore, reader, user1.address, usdt.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, usdt.target)).eq(true);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0); 

        // const collateralUni = bigNumberify("124581086072811319585049");
        // TODO:should have a constant value
        const collateralUni =  await getCollateral(dataStore, reader, user1.address, uni.target);
        const adjustAmountUsd = mulDiv(usdtAmountIn, PRECISION, bigNumberify(10)**bigNumberify(usdtDecimals));
        const adjustAmountUni = mulDiv(collateralUni, PRECISION, bigNumberify(10)**bigNumberify(uniDecimals));
        const entryLongPrice = rayDiv(adjustAmountUsd, adjustAmountUni);

        // console.log("collateralUni", collateralUni);
        // console.log("entryLongPrice", entryLongPrice);

        //expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(collateralUni);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(true);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);

        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(entryLongPrice);
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(collateralUni);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0); 
    });

    it("executeSwap long amountIn >= collateralAmount", async () => {
        await addLiquidityV3(
            user0,
            usdt,
            uni,
            dex,
            poolV3
        )

        const usdtDepositAmount = expandDecimals(1000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const usdtAmountIn = expandDecimals(2000000, usdtDecimals);
        const usdtParamsSwap: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: usdt.target,
            underlyingAssetOut: uni.target,
            amount: usdtAmountIn,
            sqrtPriceLimitX96: 0
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeSwap", [usdtParamsSwap]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);
    
        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getHasDebt(dataStore, reader, user1.address, usdt.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, usdt.target)).eq(false);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0); 

        //const collateralUni = bigNumberify("124581086072811319585049");
        // TODO:should have a constant value
        const collateralUni =  await getCollateral(dataStore, reader, user1.address, uni.target);
        const adjustAmountUsd = mulDiv(usdtDepositAmount, PRECISION, bigNumberify(10)**bigNumberify(usdtDecimals));
        const adjustAmountUni = mulDiv(collateralUni, PRECISION, bigNumberify(10)**bigNumberify(uniDecimals));
        const entryLongPrice = rayDiv(adjustAmountUsd, adjustAmountUni);

        // console.log("collateralUni", collateralUni);
        // console.log("entryLongPrice", entryLongPrice);

        //expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(collateralUni);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(true);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);

        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(entryLongPrice);
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(collateralUni);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0); 
    });

    it("executeSwap PoolNotFound", async () => {
        //amountIn pool not found
        const uniAmount = expandDecimals(100000, uniDecimals);
        const uniParams: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: ethers.ZeroAddress,
            underlyingAssetOut: usdt.target,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeSwap", [uniParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        //amountOut pool not found
        const uniParams2: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: uni.target,
            underlyingAssetOut: ethers.ZeroAddress,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };
        const multicallArgs2 = [
            exchangeRouter.interface.encodeFunctionData("executeSwap", [uniParams2]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs2)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

    });

    it("executeSwap SwapPoolsNotMatch and EmptySwapAmount", async () => {

        //swap pools not match
        const uniAmount = expandDecimals(100000, uniDecimals);
        const [eth, ethOracle] = await createAsset(
            user0, 
            config, 
            "ETH", 
            "ETH", 
            10000, 
            ethDecimals, 
            ethOracleDecimals, 
            3000
        );
        await poolFactory.createPool(eth.target, poolInterestRateStrategy.target, 0);

        const uniParams: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: eth.target,
            underlyingAssetOut: usdt.target,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("executeSwap", [uniParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs)
        ).to.be.revertedWithCustomError(errorsContract, "SwapPoolsNotMatch");


        //EmptySwapAmount
        const usdtDepositAmount = expandDecimals(1000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const usdtAmountIn = expandDecimals(0, usdtDecimals);
        const usdtParamsSwap: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: usdt.target,
            underlyingAssetOut: uni.target,
            amount: usdtAmountIn,
            sqrtPriceLimitX96: 0
        };

        const multicallArgs2 = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeSwap", [usdtParamsSwap]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgs2)
        ).to.be.revertedWithCustomError(errorsContract, "EmptySwapAmount");

    });


    it("executeSwap validateSwap underlyingAssetIn testPoolConfiguration", async () => {
        const uniAmount = expandDecimals(100000, uniDecimals);
        const uniParams: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: uni.target,
            underlyingAssetOut: usdt.target,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };

        await testPoolConfiguration(config, exchangeRouter, user1, "executeSwap", uni, uniParams)
    });

    it("executeSwap validateSwap underlyingAssetOut testPoolConfiguration", async () => {
        const uniAmount = expandDecimals(100000, uniDecimals);
        const uniParams: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: uni.target,
            underlyingAssetOut: usdt.target,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };

        await testPoolConfiguration(config, exchangeRouter, user1, "executeSwap", usdt, uniParams)
    });

}); 