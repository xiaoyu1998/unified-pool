import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, usdtOracleDecimal, uniDecimals, uniOracleDecimal} from "../../utils/constants";
import { errorsContract} from "../../utils/error";
import { parsePoolInfo} from "../../utils/helper";

describe("Config", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore, reader, configStoreUtils;
    let usdt, uni;
    let usdtPool, uniPool;

    beforeEach(async () => {
        fixture = await deployFixture();
        ({ config, dataStore, roleStore, reader, configStoreUtils } = fixture.contracts);
        ({ user0, user1, user2 } = fixture.accounts);
        ({ usdt, uni } = fixture.assets);
        ({ usdtPool, uniPool } = fixture.pools);
    });

    it("setPoolBooleans", async () => {
        // setPoolActive
        await expect(
            config.connect(user1).setPoolActive(usdtPool.underlyingAsset, true)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolActive(dataStore.target, usdtPool.underlyingAsset)
        ).eq(false);

        await expect(
            config.connect(user0).setPoolActive(ethers.ZeroAddress, true)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await config.connect(user0).setPoolActive(usdtPool.underlyingAsset, true);     
        await expect(
            await configStoreUtils.getPoolActive(dataStore.target, usdtPool.underlyingAsset)
        ).eq(true);


        // setPoolFrozen
        await expect(
            config.connect(user1).setPoolFrozen(usdtPool.underlyingAsset, true)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolFrozen(dataStore.target, usdtPool.underlyingAsset)
        ).eq(false);

        await expect(
            config.connect(user0).setPoolFrozen(ethers.ZeroAddress, true)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await config.connect(user0).setPoolFrozen(usdtPool.underlyingAsset, true);     
        await expect(
            await configStoreUtils.getPoolFrozen(dataStore.target, usdtPool.underlyingAsset)
        ).eq(true);

        // setPoolPaused
        await expect(
            config.connect(user1).setPoolPaused(usdtPool.underlyingAsset, true)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolPaused(dataStore.target, usdtPool.underlyingAsset)
        ).eq(false);

        await expect(
            config.connect(user0).setPoolPaused(ethers.ZeroAddress, true)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await config.connect(user0).setPoolPaused(usdtPool.underlyingAsset, true);     
        await expect(
            await configStoreUtils.getPoolPaused(dataStore.target, usdtPool.underlyingAsset)
        ).eq(true);

        // setPoolUsd
        await expect(
            config.connect(user1).setPoolUsd(usdtPool.underlyingAsset, true)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolUsd(dataStore.target, usdtPool.underlyingAsset)
        ).eq(false);

        await expect(
            config.connect(user0).setPoolUsd(ethers.ZeroAddress, true)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await config.connect(user0).setPoolUsd(usdtPool.underlyingAsset, true);     
        await expect(
            await configStoreUtils.getPoolUsd(dataStore.target, usdtPool.underlyingAsset)
        ).eq(true);

        // setPoolBorrowingEnabled
        await expect(
            config.connect(user1).setPoolBorrowingEnabled(usdtPool.underlyingAsset, true)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolBorrowingEnabled(dataStore.target, usdtPool.underlyingAsset)
        ).eq(false);

        await expect(
            config.connect(user0).setPoolBorrowingEnabled(ethers.ZeroAddress, true)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await config.connect(user0).setPoolBorrowingEnabled(usdtPool.underlyingAsset, true);     
        await expect(
            await configStoreUtils.getPoolBorrowingEnabled(dataStore.target, usdtPool.underlyingAsset)
        ).eq(true);
    });

    it("setPoolValues", async () => {
        // setPoolDecimals
        await expect(
            config.connect(user1).setPoolDecimals(usdtPool.underlyingAsset, 10)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolDecimals(dataStore.target, usdtPool.underlyingAsset)
        ).eq(0);

        await expect(
            config.connect(user0).setPoolDecimals(ethers.ZeroAddress, 10)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await expect(
            config.connect(user0).setPoolDecimals(usdtPool.underlyingAsset, 256)
        ).to.be.revertedWithCustomError(errorsContract, "InvalidDecimals");

        await config.connect(user0).setPoolDecimals(usdtPool.underlyingAsset, 10);     
        await expect(
            await configStoreUtils.getPoolDecimals(dataStore.target, usdtPool.underlyingAsset)
        ).eq(10);

        // setPoolFeeFactor
        await expect(
            config.connect(user1).setPoolFeeFactor(usdtPool.underlyingAsset, 10)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolFeeFactor(dataStore.target, usdtPool.underlyingAsset)
        ).eq(0);

        await expect(
            config.connect(user0).setPoolFeeFactor(ethers.ZeroAddress, 10)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await expect(
            config.connect(user0).setPoolFeeFactor(usdtPool.underlyingAsset, 65536)
        ).to.be.revertedWithCustomError(errorsContract, "InvalidFeeFactor");

        await config.connect(user0).setPoolFeeFactor(usdtPool.underlyingAsset, 10);     
        await expect(
            await configStoreUtils.getPoolFeeFactor(dataStore.target, usdtPool.underlyingAsset)
        ).eq(10);
        
        // setPoolBorrowCapacity
        await expect(
            config.connect(user1).setPoolBorrowCapacity(usdtPool.underlyingAsset, 10)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolBorrowCapacity(dataStore.target, usdtPool.underlyingAsset)
        ).eq(0);

        await expect(
            config.connect(user0).setPoolBorrowCapacity(ethers.ZeroAddress, 10)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await expect(
            config.connect(user0).setPoolBorrowCapacity(usdtPool.underlyingAsset, 68719476736)
        ).to.be.revertedWithCustomError(errorsContract, "InvalidBorrowCapacity");

        await config.connect(user0).setPoolBorrowCapacity(usdtPool.underlyingAsset, 100000000);     
        await expect(
            await configStoreUtils.getPoolBorrowCapacity(dataStore.target, usdtPool.underlyingAsset)
        ).eq(100000000);

        // setPoolSupplyCapacity
        await expect(
            config.connect(user1).setPoolSupplyCapacity(usdtPool.underlyingAsset, 10)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");

        await expect(
            await configStoreUtils.getPoolSupplyCapacity(dataStore.target, usdtPool.underlyingAsset)
        ).eq(0);

        await expect(
            config.connect(user0).setPoolSupplyCapacity(ethers.ZeroAddress, 10)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await expect(
            config.connect(user0).setPoolSupplyCapacity(usdtPool.underlyingAsset, 68719476736)
        ).to.be.revertedWithCustomError(errorsContract, "InvalidSupplyCapacity");

        await config.connect(user0).setPoolSupplyCapacity(usdtPool.underlyingAsset, 100000000);     
        await expect(
            await configStoreUtils.getPoolSupplyCapacity(dataStore.target, usdtPool.underlyingAsset)
        ).eq(100000000);
     });

}); 