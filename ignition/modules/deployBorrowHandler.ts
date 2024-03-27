import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { borrowUtilsModule } from "./deployBorrowUtils"
import { hashString } from "../../utils/hash";
import "../../utils/keys";

export const borrowHandlerModule = buildModule("BorrowHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { borrowUtils } = m.useModule(borrowUtilsModule)

    const borrowHandler = m.contract("BorrowHandler", [roleStore, dataStore], {
        libraries: {
            BorrowUtils: borrowUtils,
        },    
    });

    m.call(roleStore, "grantRole",  [borrowHandler, keys.CONTROLLER]);

    return { borrowHandler };
});

//export default borrowHandlerModule;