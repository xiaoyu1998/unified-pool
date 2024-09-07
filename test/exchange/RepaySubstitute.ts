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
import { SwapUtils } from "../typechain-types/contracts/exchange/SwapHandler";
import { testPoolConfiguration} from "../../utils/pool";
import { createAsset, createUniswapV3, addLiquidityV3 } from "../../utils/assetsDex";

describe("Exchange RepaySubstitute", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, router, exchangeRouter;
    let usdt, uni;
    let dex, poolV3;
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

        await addLiquidityV3(
            user0,
            usdt,
            uni,
            dex,
            poolV3
        )

    });

    it("executeRepay useCollateralToRepay allCollateral", async () => {

        const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: usdt.target,
        };

        const uniDepositAmount = expandDecimals(100000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniDepositAmount);
        const uniParamsDeposit: DepositUtils.DepositParamsStructOutput = {
            underlyingAsset: uni.target,
        };

        const uniBorrowAmmount = expandDecimals(200000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };
        const paramsSwap: SwapUtils.SwapParamsStruct = {
            underlyingAssetIn: uni.target,
            underlyingAssetOut: usdt.target,
            amount: uniBorrowAmmount,
            sqrtPriceLimitX96: 0
        };

        const uniAmountRepay = uniDepositAmount + expandDecimals(1, uniDecimals);//repay amount larger than collateral
        const uniParamsRepay: RepayUtils.RepayParamsStructOutput = {
            underlyingAsset: uni.target,
            amount: uniAmountRepay,
            substitute: ethers.ZeroAddress,//set ZeroAddress, replay by all usdt collteral
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeSwap", [paramsSwap]),
            exchangeRouter.interface.encodeFunctionData("executeRepaySubstitute", [uniParamsRepay]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);
    
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(uniBorrowAmmount - uniDepositAmount);
        expect(await getHasDebt(dataStore, reader, user1.address, uni.target)).eq(true);
        expect(await getHasCollateral(dataStore, reader, user1.address, uni.target)).eq(false);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(0);//short
    });

}); 