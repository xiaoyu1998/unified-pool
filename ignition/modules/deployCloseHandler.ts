import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { closeUtilsModule } from "./deployCloseUtils"
import { eventEmitterModule } from "./deployEventEmitter"

export const closeHandlerModule = buildModule("CloseHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { closeUtils } = m.useModule(closeUtilsModule)
    const { eventEmitter } = m.useModule(eventEmitterModule)

    const closeHandler = m.contract("CloseHandler", [roleStore, dataStore, eventEmitter], {
        libraries: {
            CloseUtils: closeUtils,
        },    
    });

    //m.call(roleStore, "grantRole",  [closeHandler, keys.CONTROLLER]);
    return { closeHandler };
});

export default closeHandlerModule;