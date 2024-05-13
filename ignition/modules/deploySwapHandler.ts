import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { swapUtilsModule } from "./deploySwapUtils"
import { eventEmitterModule } from "./deployEventEmitter"

export const swapHandlerModule = buildModule("SwapHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { swapUtils } = m.useModule(swapUtilsModule)
    const { eventEmitter } = m.useModule(eventEmitterModule)

    const swapHandler = m.contract("SwapHandler", [roleStore, dataStore, eventEmitter], {
        libraries: {
            SwapUtils: swapUtils,
        },    
    });

    //m.call(roleStore, "grantRole",  [swapHandler, keys.CONTROLLER]);
    return { swapHandler };
});

export default swapHandlerModule;