import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { ProtocolErrors, errorsContract} from "../../utils/error";
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
import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";
import { createAsset, createUniswapV3, addLiquidityV3 } from "../../utils/assetsDex";
import { testPoolConfiguration } from "../../utils/pool";
import { ethDecimals, ethOracleDecimals, PRECISION } from "../../utils/constants";

describe("Exchange Liquidation", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, router, exchangeRouter, poolFactory, poolInterestRateStrategy;
    let usdt, uni;
    let usdtPool, uniPool;
    let usdtDecimals, usdtOracleDecimals, uniDecimals, uniOracleDecimals;
    let dex, poolV3;

    const {
        ERC20_DECREASED_ALLOWANCE_BELOW_ZERO,
        ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE,
    } = ProtocolErrors;


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

    it("executeLiquidation liquidator insufficient balance", async () => {
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
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            // exchangeRouter.interface.encodeFunctionData("executeLiquidation", [liquidationParams]),
        ];

        await exchangeRouter.connect(user1).multicall(multicallArgs);
        await config.setHealthFactorLiquidationThreshold(expandDecimals(400, 25));//400%

        const liquidationParams: LiquidationUtils.LiquidationParamsStructOutput = {
            account: user1.address
        };

        const multicallArgs2 = [
            exchangeRouter.interface.encodeFunctionData("executeLiquidation", [liquidationParams]),
        ];
        await expect(
            exchangeRouter.connect(user2).multicall(multicallArgs2)
        ).to.be.revertedWith(ERC20_DECREASED_ALLOWANCE_BELOW_ZERO);  
    });

    // it("executeLiquidation validateLiquidation HealthFactorHigherThanLiquidationThreshold", async () => {
    //     const usdtDepositAmount = expandDecimals(1000000, usdtDecimals);
    //     await usdt.connect(user1).approve(router.target, usdtDepositAmount);
    //     const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
    //         underlyingAsset: usdt.target,
    //     };
    //     const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
    //     const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
    //         underlyingAsset: uni.target,
    //         amount: uniBorrowAmmount,
    //     };
    //     const liquidationParams: LiquidationUtils.LiquidationParamsStructOutput = {
    //         account: user1.address
    //     };
    //     const multicallArgs = [
    //         exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
    //         exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
    //         exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
    //         exchangeRouter.interface.encodeFunctionData("executeLiquidation", [liquidationParams]),
    //     ];
    //     await expect(
    //         exchangeRouter.connect(user1).multicall(multicallArgs)
    //     ).to.be.revertedWithCustomError(errorsContract, "HealthFactorHigherThanLiquidationThreshold");   
       
    // });

    // it("executeLiquidation testPoolConfiguration", async () => {
    //     const usdtDepositAmount = expandDecimals(1000000, usdtDecimals);
    //     await usdt.connect(user1).approve(router.target, usdtDepositAmount);
    //     const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
    //         underlyingAsset: usdt.target,
    //     };
    //     const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
    //     const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
    //         underlyingAsset: uni.target,
    //         amount: uniBorrowAmmount,
    //     };
    //     const multicallArgs = [
    //         exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
    //         exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
    //         exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
    //         // exchangeRouter.interface.encodeFunctionData("executeLiquidation", [liquidationParams]),
    //     ];

    //     await exchangeRouter.connect(user1).multicall(multicallArgs);
    //     await config.setHealthFactorLiquidationThreshold(expandDecimals(400, 25));//400%

    //     const liquidationParams: LiquidationUtils.LiquidationParamsStructOutput = {
    //         account: user1.address
    //     };

    //     await testPoolConfiguration(config, exchangeRouter, user1, "executeLiquidation", usdt, liquidationParams)
       
    // });

}); 