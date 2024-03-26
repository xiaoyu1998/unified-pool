import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"

const configModule = buildModule("Config", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)

    const config = m.contract("Config", [roleStore, dataStore], {
        libraries: {
            PoolStoreUtils: poolStoreUtils
        },
    });

    return { config };
});

export default configModule;