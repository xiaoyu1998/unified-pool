import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
// import * as keys from "../../utils/keys";

export const poolFactoryModule = buildModule("PoolFactory", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)

    const poolFactory = m.contract("PoolFactory", [roleStore, dataStore], {
        libraries: {
            PoolStoreUtils: poolStoreUtils
        },
    });
    //m.call(roleStore, "grantRole",  [poolFactory, keys.CONTROLLER]);
    return { poolFactory };
});

export default poolFactoryModule;