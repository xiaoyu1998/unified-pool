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

    it("executeDepositBorrow", async () => {
        const usdtBalanceBeforeTxnPool = await usdt.balanceOf(usdtPool.poolToken);
        const uniBalanceBeforeTxnPool = await uni.balanceOf(uniPool.poolToken);
        const usdtBalanceBeforeTxnUser1 = await usdt.balanceOf(user1.address);
        const uniBalanceBeforeTxnUser1 = await uni.balanceOf(user1.address);

        //Deposit
        const usdtAmountDeposit = expandDecimals(10000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtAmountDeposit);
        const uniAmountDeposit = expandDecimals(200000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniAmountDeposit);
        const usdtParamsDeposit: DepositUtils.DepositParamsStruct = {
            underlyingAsset: usdt.target,
        };
        const uniParamsDeposit: DepositUtils.DepositParamsStruct = {
            underlyingAsset: uni.target,
        };

        const multicallArgsDeposit = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniAmountDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsDeposit);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforeTxnPool + usdtAmountDeposit);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeTxnUser1 - usdtAmountDeposit);
        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtAmountDeposit);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0);  
        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforeTxnPool + uniAmountDeposit);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeTxnUser1 - uniAmountDeposit);
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniAmountDeposit);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(expandDecimals(8, 27));
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(uniAmountDeposit);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0);

        //borrow 
        const usdtCollateralBeforeBorrowUser1 = await getCollateral(dataStore, reader, user1.address, usdt.target);
        const uniCollateralBeforeBorrowUser1 = await getCollateral(dataStore, reader, user1.address, uni.target);

        const usdtAmmountBorrow = expandDecimals(1000000, usdtDecimals);
        const usdtParamsBorrow: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: usdt.target,
            amount: usdtAmmountBorrow,
        };
        const uniAmmountBorrow = expandDecimals(900000, uniDecimals);
        const uniParamsBorrow: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: uni.target,
            amount: uniAmmountBorrow,
        };
        const multicallArgsBorrow = [
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [usdtParamsBorrow]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [uniParamsBorrow]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsBorrow);

        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtCollateralBeforeBorrowUser1 + usdtAmmountBorrow);
        expect(await getDebt(dataStore, reader, user1.address, usdt.target)).eq(usdtAmmountBorrow);
        expect(await getSupplyApy(dataStore, reader, user1.address, usdt.target)).eq("6243750000000000000000000");
        expect(await getBorrowApy(dataStore, reader, user1.address, usdt.target)).eq("62500000000000000000000000");
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniCollateralBeforeBorrowUser1 + uniAmmountBorrow);
        expect(await getDebt(dataStore, reader, user1.address, uni.target)).eq(uniAmmountBorrow);
        expect(await getSupplyApy(dataStore, reader, user1.address, uni.target)).eq("674325000000000000000000000");
        expect(await getBorrowApy(dataStore, reader, user1.address, uni.target)).eq("750000000000000000000000000");

    });

}); 