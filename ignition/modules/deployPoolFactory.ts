import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"

const poolFactoryrModule = buildModule("PoolFactory", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)

    const poolFactory = m.contract("PoolFactory", [roleStore, dataStore], {
        libraries: {
            PoolStoreUtils: poolStoreUtils
        },
    });
    m.call(roleStore, "grantRole",  [supplyHandler, hashString("CONTROLLER")]);

    return { poolFactory };
});

export default poolFactoryrModule;