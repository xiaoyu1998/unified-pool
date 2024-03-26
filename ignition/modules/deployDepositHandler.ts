import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { depositUtilsModule } from "./deployDepositUtils"

export const depositHandlerModule = buildModule("DepositHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { depositUtils } = m.useModule(depositUtilsModule)

    const depositHandler = m.contract("DepositHandler", [roleStore, dataStore], {
        libraries: {
            DepositUtils: depositUtils,
        },    
    });

    return { depositHandler };
});

//export default depositHandlerModule;