import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { liquidationUtilsModule } from "./deployLiquidationUtils"
import { eventEmitterModule } from "./deployEventEmitter"

export const liquidationHandlerModule = buildModule("LiquidationHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { liquidationUtils } = m.useModule(liquidationUtilsModule)
    const { eventEmitter } = m.useModule(eventEmitterModule)

    const liquidationHandler = m.contract("LiquidationHandler", [roleStore, dataStore, eventEmitter], {
        libraries: {
            LiquidationUtils: liquidationUtils,
        },    
    });

    return { liquidationHandler };
});

export default liquidationHandlerModule;