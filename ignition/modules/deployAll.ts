import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
// import { roleStoreModule } from "./deployRoleStore"
// import { dataStoreModule } from "./deployDataStore"
// import { borrowUtilsModule } from "./deployBorrowUtils"
// import { hashString } from "../../utils/hash";
// import * as keys from "../../utils/keys";

import { configModule } from "./deployConfig"

const all = buildModule("All", (m) => {
    const { config } = m.useModule(configModule)
    const { config } = m.useModule(configModule)    



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

export default borrowHandlerModule;