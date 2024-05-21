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
import { SupplyUtils } from "../../typechain-types/contracts/exchange/SupplyHandler";
import { WithdrawUtils } from "../typechain-types/contracts/exchange/WithdrawHandler";

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

    it("executeRedeem", async () => {
        // const usdtBalanceBeforeDepositPool = await usdt.balanceOf(usdtPool.poolToken);
        // const uniBalanceBeforeDepositPool = await uni.balanceOf(uniPool.poolToken);
        // const usdtBalanceBeforeDepositUser1 = await usdt.balanceOf(user1.address);
        // const uniBalanceBeforeDepositUser1 = await uni.balanceOf(user1.address);

        //Deposit
        const usdtDepositAmount = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const uniDepositAmount = expandDecimals(200000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStruct = {
            underlyingAsset: usdt.target,
        };
        const uniParamsDeposit: DepositUtils.DepositParamsStruct = {
            underlyingAsset: uni.target,
        };
        
        //Borrow
        const usdtBorrowAmmount = expandDecimals(1000000, usdtDecimals);
        const usdtParamsBorrow: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: usdt.target,
            amount: usdtBorrowAmmount,
        };
        const uniBorrowAmmount = expandDecimals(100000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: uni.target,
            amount: uniBorrowAmmount,
        };

        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);

        const usdtBalanceBeforeRedeemPool = await usdt.balanceOf(usdtPool.poolToken);
        const uniBalanceBeforeRedeemPool = await uni.balanceOf(uniPool.poolToken);
        const usdtBalanceBeforeRedeemUser1 = await usdt.balanceOf(user1.address);
        const uniBalanceBeforeRedeemUser1 = await uni.balanceOf(user1.address);
        const uniCollateralBeforeBorrowUser1 = uniDepositAmount + uniBorrowAmmount;

        //Redeem
        const usdtAmountRedeem = expandDecimals(1000000, usdtDecimals);
        const usdtParamsRedeem: RedeemUtils.RedeemParamsStruct = {
            underlyingAsset: usdt.target,
            amount: usdtAmountRedeem,
            to:user1.address
        };
        const uniAmountRedeem = expandDecimals(400000, uniDecimals);
        const uniParamsRedeem: RedeemUtils.RedeemParamsStruct = {
            underlyingAsset: uni.target,
            amount: uniAmountRedeem,
            to:user1.address
        };

        const multicallArgsRedeem = [
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [usdtParamsRedeem]),
            exchangeRouter.interface.encodeFunctionData("executeRedeem", [uniParamsRedeem]),
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

}); 