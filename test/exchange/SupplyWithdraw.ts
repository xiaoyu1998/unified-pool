import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, uniDecimals} from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"
import { getSupply } from "../../utils/helper"
import { SupplyUtils } from "../../typechain-types/contracts/exchange/SupplyHandler";
import { WithdrawUtils } from "../typechain-types/contracts/exchange/WithdrawHandler";

// export async function getSupply(dataStore, reader, address, underlyingAsset) {
//     const {balanceSupply } = await getMarginAndSupply(dataStore, reader, address, underlyingAsset);
//     return balanceSupply;
// }

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

    it("executeSupplyWithdraw", async () => {
        const usdtBalanceBeforeSupplyPool = await usdt.balanceOf(usdtPool.poolToken);
        const uniBalanceBeforeSupplyPool = await uni.balanceOf(uniPool.poolToken);
        const usdtBalanceBeforeSupplyUser1 = await usdt.balanceOf(user1.address);
        const uniBalanceBeforeSupplyUser1 = await uni.balanceOf(user1.address);

        //Supply
        const usdtSupplyAmount = expandDecimals(8000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtSupplyAmount);
        const uniSupplyAmount = expandDecimals(800000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniSupplyAmount);

        const usdtParamsSupply: SupplyUtils.SupplyParamsStruct = {
            underlyingAsset: usdt.target,
            to: user1.address,
        };
        const uniParamsSupply: SupplyUtils.SupplyParamsStruct = {
            underlyingAsset: uni.target,
            to: user1.address,
        };

        const multicallArgsSupply = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtSupplyAmount]),
            exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParamsSupply]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniSupplyAmount]),
            exchangeRouter.interface.encodeFunctionData("executeSupply", [uniParamsSupply]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsSupply);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforeSupplyPool + usdtSupplyAmount);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeSupplyUser1 - usdtSupplyAmount);
        expect(await getSupply(dataStore, reader, user1.address, usdt.target)).eq(usdtSupplyAmount);
        
        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforeSupplyPool + uniSupplyAmount);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeSupplyUser1 - uniSupplyAmount);
        expect(await getSupply(dataStore, reader, user1.address, uni.target)).eq(uniSupplyAmount);

        //Withdraw
        const usdtBalanceBeforeWithdrawPool = await usdt.balanceOf(usdtPool.poolToken);
        const uniBalanceBeforeWithdrawPool = await uni.balanceOf(uniPool.poolToken);
        const usdtBalanceBeforeWithdrawUser1 = await usdt.balanceOf(user1.address);
        const uniBalanceBeforeWithdrawUser1 = await uni.balanceOf(user1.address);
        const usdtSupplyBeforeWithdrawUser1 = await getSupply(dataStore, reader, user1.address, usdt.target);
        const uniSupplyBeforeWithdrawUser1 = await getSupply(dataStore, reader, user1.address, uni.target);

        const usdtWithdrawAmount = expandDecimals(2000000, usdtDecimals);
        const uniWithdrawAmount = expandDecimals(200000, uniDecimals);

        const usdtParamsDeposit: WithdrawUtils.WithdrawParamsStruct = {
            underlyingAsset: usdt.target,
            amount: usdtWithdrawAmount,
            to: user1.address,
        };
        const uniParamsDeposit: WithdrawUtils.WithdrawParamsStruct = {
            underlyingAsset: uni.target,
            amount: uniWithdrawAmount,
            to: user1.address,
        };

        const multicallArgsWithdraw = [
            exchangeRouter.interface.encodeFunctionData("executeWithdraw", [usdtParamsDeposit]),
            exchangeRouter.interface.encodeFunctionData("executeWithdraw", [uniParamsDeposit]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsWithdraw);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforeWithdrawPool - usdtWithdrawAmount);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeWithdrawUser1 + usdtWithdrawAmount);
        expect(await getSupply(dataStore, reader, user1.address, usdt.target)).eq(usdtSupplyBeforeWithdrawUser1 - usdtWithdrawAmount);

        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniBalanceBeforeWithdrawPool - uniWithdrawAmount);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeWithdrawUser1 + uniWithdrawAmount);
        expect(await getSupply(dataStore, reader, user1.address, uni.target)).eq(uniSupplyBeforeWithdrawUser1 - uniWithdrawAmount);

    });

}); 