import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, usdtDecimals} from "../../utils/constants";
import { expandDecimals, bigNumberify } from "../../utils/math"
import { getSupply } from "../../utils/helper"
import { SupplyUtils } from "../../typechain-types/contracts/exchange/SupplyHandler";
import { errorsContract} from "../../utils/error";
import { testPoolConfiguration} from "../../utils/poolConfiguration";

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

    it("executeSupply", async () => {
        const usdtBalanceBeforeSupplyPool = await usdt.balanceOf(usdtPool.poolToken);
        const usdtBalanceBeforeSupplyUser1 = await usdt.balanceOf(user1.address);
        const usdtSupplyAmount = expandDecimals(8000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtSupplyAmount);
        const usdtParamsSupply: SupplyUtils.SupplyParamsStructOutput = {
            underlyingAsset: usdt.target,
            to: user1.address,
        };
        const multicallArgsSupply = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtSupplyAmount]),
            exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParamsSupply]),
        ];
        await exchangeRouter.connect(user1).multicall(multicallArgsSupply);
        expect(await usdt.balanceOf(usdtPool.poolToken)).eq(usdtBalanceBeforeSupplyPool + usdtSupplyAmount);
        expect(await usdt.balanceOf(user1.address)).eq(usdtBalanceBeforeSupplyUser1 - usdtSupplyAmount);
        expect(await getSupply(dataStore, reader, user1.address, usdt.target)).eq(usdtSupplyAmount);
    });

    it("executeSupply PoolNotFound", async () => {
        const usdtParamsSupply: SupplyUtils.SupplyParamsStructOutput = {
            underlyingAsset: ethers.ZeroAddress,
            to: user1.address,
        };
        const multicallArgsSupply = [
            exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParamsSupply]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsSupply)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

    });

    it("executeSupply validateSupply", async () => {
        //EmptySupplyAmounts
        const usdtSupplyAmount = expandDecimals(8000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtSupplyAmount);
        const usdtParamsSupply: SupplyUtils.SupplyParamsStructOutput = {
            underlyingAsset: usdt.target,
            to: user1.address,
        };
        const multicallArgsSupply = [
            exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParamsSupply]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsSupply)
        ).to.be.revertedWithCustomError(errorsContract, "EmptySupplyAmounts");

        //SupplyCapacityExceeded
        const multicallArgsConfig = [
            config.interface.encodeFunctionData("setPoolSupplyCapacity", [usdt.target, expandDecimals(1, 7)]),
        ];
        await config.multicall(multicallArgsConfig);

        const multicallArgsSupply2 = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtSupplyAmount]),
            exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParamsSupply]),
        ];
        await expect(
            exchangeRouter.connect(user1).multicall(multicallArgsSupply2)
        ).to.be.revertedWithCustomError(errorsContract, "SupplyCapacityExceeded");

    });


    it("executeSupply validateSupply poolConfiguration", async () => {

        const usdtSupplyAmount = expandDecimals(8000000, usdtDecimals);
        await usdt.connect(user1).approve(router.target, usdtSupplyAmount);
        const usdtParamsSupply: SupplyUtils.SupplyParamsStructOutput = {
            underlyingAsset: usdt.target,
            to: user1.address,
        };

        await testPoolConfiguration(config, exchangeRouter, user1, "executeSupply", usdt, usdtParamsSupply)

        // const multicallArgsConfig = [
        //     config.interface.encodeFunctionData("setPoolActive", [usdt.target, false]),
        //     config.interface.encodeFunctionData("setPoolFrozen", [usdt.target, false]),
        //     config.interface.encodeFunctionData("setPoolPaused", [usdt.target, false]),
        // ];
        // await config.multicall(multicallArgsConfig);

        // const multicallArgsSupply = [
        //     exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParamsSupply]),
        // ];
        // await expect(
        //     exchangeRouter.connect(user1).multicall(multicallArgsSupply)
        // ).to.be.revertedWithCustomError(errorsContract, "PoolIsInactive");  

        // //PoolIsFrozen
        // const multicallArgsConfig2 = [
        //     config.interface.encodeFunctionData("setPoolActive", [usdt.target, true]),
        //     config.interface.encodeFunctionData("setPoolFrozen", [usdt.target, true]),
        //     config.interface.encodeFunctionData("setPoolPaused", [usdt.target, false]),
        // ];
        // await config.multicall(multicallArgsConfig2);   
        // await expect(
        //     exchangeRouter.connect(user1).multicall(multicallArgsSupply)
        // ).to.be.revertedWithCustomError(errorsContract, "PoolIsFrozen");  

        // //PoolIsPaused
        // const multicallArgsConfig3 = [
        //     config.interface.encodeFunctionData("setPoolActive", [usdt.target, true]),
        //     config.interface.encodeFunctionData("setPoolFrozen", [usdt.target, false]),
        //     config.interface.encodeFunctionData("setPoolPaused", [usdt.target, true]),
        // ];
        // await config.multicall(multicallArgsConfig3);   
        // await expect(
        //     exchangeRouter.connect(user1).multicall(multicallArgsSupply)
        // ).to.be.revertedWithCustomError(errorsContract, "PoolIsPaused");     
    });

}); 