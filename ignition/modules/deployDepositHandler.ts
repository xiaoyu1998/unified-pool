import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { depositUtilsModule } from "./deployDepositUtils"
import { hashString } from "../../utils/hash";

export const depositHandlerModule = buildModule("DepositHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { depositUtils } = m.useModule(depositUtilsModule)

    const depositHandler = m.contract("DepositHandler", [roleStore, dataStore], {
        libraries: {
            DepositUtils: depositUtils,
        },    
    });

    m.call(roleStore, "grantRole",  [depositHandler, hashString("CONTROLLER")]);

    return { depositHandler };
});

//export default depositHandlerModule;