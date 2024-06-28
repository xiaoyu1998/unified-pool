import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
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
import { SwapUtils } from "../typechain-types/contracts/exchange/SwapHandler";
import { createAsset, createUniswapV3 } from "../../utils/assetsDex";
import { testPoolConfiguration } from "../../utils/pool";
import { ethDecimals, ethOracleDecimals } from "../../utils/constants";

describe("Exchange Swap", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, router, exchangeRouter, poolFactory, poolInterestRateStrategy;
    let usdt, uni;
    let usdtPool, uniPool;
    let usdtDecimals, usdtOracleDecimals, uniDecimals, uniOracleDecimals;
    let dex;

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

        const dex = await createUniswapV3(
            user0, 
            config, 
            usdt, 
            usdtDecimals, 
            uni, 
            uniDecimals, 
            8
        );

    });

    // it("executeSwap useCollateralToSwap noDebt hasCollateral", async () => {
    //     const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
    //     await usdt.connect(user1).approve(router.target, usdtDepositAmount);
    //     const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
    //         underlyingAsset: usdt.target,
    //     };
    //     const usdtBorrowAmmount = expandDecimals(1000000, usdtDecimals);
    //     const usdtParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
    //         underlyingAsset: usdt.target,
    //         amount: usdtBorrowAmmount,
    //     };
    //     const usdtAmountSwap = expandDecimals(1000000, usdtDecimals);
    //     const usdtParamsSwap: SwapUtils.SwapParamsStructOutput = {
    //         underlyingAsset: usdt.target,
    //         amount: usdtAmountSwap,
    //     };

    //     const multicallArgs = [
    //         exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
    //         exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
    //         exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
    //         exchangeRouter.interface.encodeFunctionData("executeSwap", [usdtParamsSwap]),
    //     ];
    //     await exchangeRouter.connect(user1).multicall(multicallArgs);
    
    //     expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtDepositAmount + usdtBorrowAmmount - usdtAmountSwap);
    //     expect(await getDebt(dataStore, reader, user1.address, usdt.target)).eq(usdtBorrowAmmount - usdtAmountSwap);
    //     expect(await getHasDebt(dataStore, reader, user1.address, usdt.target)).eq(false);
    //     expect(await getHasCollateral(dataStore, reader, user1.address, usdt.target)).eq(true);
    //     expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
    //     expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
    //     expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
    //     expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
    //     expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0); 
    // });


    it("executeSwap PoolNotFound", async () => {
        const uniAmount = expandDecimals(100000, uniDecimals);
        const uniParams: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: ethers.ZeroAddress,
            underlyingAssetOut: usdt.target,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };
        const multicallArgsSwap = [
            exchangeRouter.interface.encodeFunctionData("executeSwap", [uniParams]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsSwap)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        const uniParams2: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: uni.target,
            underlyingAssetOut: ethers.ZeroAddress,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };
        const multicallArgsSwap2 = [
            exchangeRouter.interface.encodeFunctionData("executeSwap", [uniParams2]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsSwap2)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");


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

        const uniParams3: SwapUtils.SwapParamsStructOutput = {
            underlyingAssetIn: eth.target,
            underlyingAssetOut: usdt.target,
            amount: uniAmount,
            sqrtPriceLimitX96: 0
        };
        const multicallArgsSwap3 = [
            exchangeRouter.interface.encodeFunctionData("executeSwap", [uniParams3]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsSwap3)
        ).to.be.revertedWithCustomError(errorsContract, "SwapPoolsNotMatch");
    });

    // it("executeSwap validateSwap", async () => {

    // });

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