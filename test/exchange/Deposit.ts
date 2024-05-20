import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, uniDecimals, usdtOracleDecimal, uniOracleDecimal} from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"
import { getCollateral, getPositionType, getEntryLongPrice, getAccLongAmount, getEntryShortPrice, getAccShortAmount } from "../../utils/helper"
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

    it("executeDeposit", async () => {
        const usdtBalanceBeforeTxnPool = await usdt.balanceOf(usdtPool.poolToken);
        const uniBalanceBeforeTxnPool = await uni.balanceOf(uniPool.poolToken);
        const usdtBalanceBeforeTxnUser1 = await usdt.balanceOf(user1.address);
        const uniBalanceBeforeTxnUser1 = await uni.balanceOf(user1.address);

        //Deposit
        const usdtDepositAmount = expandDecimals(1000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtDepositAmount);
        const uniDepositAmount = expandDecimals(100000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniDepositAmount);
        const usdtParamsDeposit: DepositUtils.DepositParamsStruct = {
            underlyingAsset: usdt.target,
        };
        const uniParamsDeposit: DepositUtils.DepositParamsStruct = {
            underlyingAsset: uni.target,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniDepositAmount]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [uniParamsDeposit]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforeTxnPool + usdtDepositAmount);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeTxnUser1 - usdtDepositAmount);
        expect(await getCollateral(dataStore, reader, user1.address, usdt.target)).eq(usdtDepositAmount);
        expect(await getPositionType(dataStore, reader, user1.address, usdt.target)).eq(2);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccLongAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, usdt.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, usdt.target)).eq(0);
        
        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforeTxnPool + uniDepositAmount);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeTxnUser1 - uniDepositAmount);
        expect(await getCollateral(dataStore, reader, user1.address, uni.target)).eq(uniDepositAmount);
        expect(await getPositionType(dataStore, reader, user1.address, uni.target)).eq(1);
        expect(await getEntryLongPrice(dataStore, reader, user1.address, uni.target)).eq(expandDecimals(8, 27));
        expect(await getAccLongAmount(dataStore, reader, user1.address, uni.target)).eq(uniDepositAmount);
        expect(await getEntryShortPrice(dataStore, reader, user1.address, uni.target)).eq(0);
        expect(await getAccShortAmount(dataStore, reader, user1.address, uni.target)).eq(0);

    });

}); 