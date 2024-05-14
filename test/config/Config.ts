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

    it("setPoolDecimals", async () => {
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
    });
}); 