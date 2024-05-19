import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, uniDecimals} from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"
import { getMarginAndSupply } from "../../utils/helper"
import { SupplyUtils } from "../../typechain-types/contracts/exchange/SupplyHandler";

export async function getSupply(dataStore, reader, address, underlyingAsset) {
    const {balanceSupply } = await getMarginAndSupply(dataStore, reader, address, underlyingAsset);
    return balanceSupply;
}

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

    it("executeSupply", async () => {

        const usdtBalanceBeforeUser1 = await usdt.balanceOf(user1.address);
        const uniBalanceBeforeUser1 = await uni.balanceOf(user1.address);

        const usdtSupplyAmount = expandDecimals(8000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtSupplyAmount);
        const uniSupplyAmount = expandDecimals(800000, uniDecimals);
        await uni.connect(user1).approve(router.target, uniSupplyAmount);

        const usdtParams: SupplyUtils.SupplyParamsStruct = {
            underlyingAsset: usdt.target,
            to: user1.address,
        };
        const uniParams: SupplyUtils.SupplyParamsStruct = {
            underlyingAsset: uni.target,
            to: user1.address,
        };

        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtSupplyAmount]),
            exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParams]),
            exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniSupplyAmount]),
            exchangeRouter.interface.encodeFunctionData("executeSupply", [uniParams]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgs);

        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtSupplyAmount);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeUser1 - usdtSupplyAmount);
        expect(await uni.balanceOf(uniPool.poolToken)).eq(uniSupplyAmount);
        expect(await uni.balanceOf(user1.address)).eq(uniBalanceBeforeUser1 - uniSupplyAmount);

        expect(await getSupply(dataStore, reader, user1.address, usdt.target)).eq(usdtSupplyAmount);
        expect(await getSupply(dataStore, reader, user1.address, uni.target)).eq(uniSupplyAmount);

    });

}); 