import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { borrowUtilsModule } from "./deployBorrowUtils"
import { eventEmitterModule } from "./deployEventEmitter"

export const borrowHandlerModule = buildModule("BorrowHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { borrowUtils } = m.useModule(borrowUtilsModule)
    const { eventEmitter } = m.useModule(eventEmitterModule)

    const borrowHandler = m.contract("BorrowHandler", [roleStore, dataStore, eventEmitter], {
        libraries: {
            BorrowUtils: borrowUtils,
        },    
    });

    //m.call(roleStore, "grantRole",  [borrowHandler, keys.CONTROLLER]);

    return { borrowHandler };
});

//export default borrowHandlerModule;