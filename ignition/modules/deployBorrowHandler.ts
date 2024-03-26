import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { borrowUtilsModule } from "./deployBorrowUtils"

export const borrowHandlerModule = buildModule("BorrowHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { borrowUtils } = m.useModule(borrowUtilsModule)

    const borrowHandler = m.contract("BorrowHandler", [roleStore, dataStore], {
        libraries: {
            BorrowUtils: borrowUtils,
        },    
    });

    return { borrowHandler };
});

//export default borrowHandlerModule;