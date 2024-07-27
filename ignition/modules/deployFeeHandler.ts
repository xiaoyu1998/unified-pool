import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { eventEmitterModule } from "./deployEventEmitter"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { feeStoreUtilsModule } from "./deployFeeStoreUtils"

export const feeHandlerModule = buildModule("FeeHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { eventEmitter } = m.useModule(eventEmitterModule)
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { feeStoreUtils } = m.useModule(feeStoreUtilsModule)

    const feeHandler = m.contract("FeeHandler", [roleStore, dataStore, eventEmitter], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            FeeStoreUtils: feeStoreUtils
        },    
    });

    return { feeHandler };
});

export default feeHandlerModule;