import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";
import { usdtDecimals, usdtOracleDecimal, uniDecimals, uniOracleDecimal} from "../../utils/constants";
import { errorsContract} from "../../utils/error";

describe("Config", () => {
    let fixture;
    let user0, user1, user2;
    let config, dataStore, roleStore;
    let usdt, uni;
    let usdtPool, uniPool;

    beforeEach(async () => {
        fixture = await deployFixture();
        ({ config, dataStore, roleStore } = fixture.contracts);
        ({ user0, user1, user2 } = fixture.accounts);
        ({ usdt, uni } = fixture.assets);
        ({ usdtPool, uniPool } = fixture.pools);
    });

    it("setPoolDecimals", async () => {
        await expect(
            config.connect(user1).setPoolDecimals(usdtPool.underlyingAsset, 10)
        ).to.be.revertedWithCustomError(errorsContract, "Unauthorized");
        // await expect(
        //     dataStore.getPoolDecimals(usdtPool.underlyingAsset)
        // ).eq(0);

        await expect(
            config.connect(user0).setPoolDecimals(ethers.ZeroAddress, 10)
        ).to.be.revertedWithCustomError(errorsContract, "PoolNotFound");

        await expect(
            config.connect(user0).setPoolDecimals(usdtPool.underlyingAsset, 256)
        ).to.be.revertedWithCustomError(errorsContract, "InvalidDecimals");

        await config.connect(user0).setPoolDecimals(usdtPool.underlyingAsset, 10);
        // await expect(
        //     dataStore.getPoolDecimals(usdtPool.underlyingAsset)
        // ).eq(10);
    });
}); 