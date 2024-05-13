import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { depositUtilsModule } from "./deployDepositUtils"
import { eventEmitterModule } from "./deployEventEmitter"
//import { hashString } from "../../utils/hash";
//import * as keys from "../../utils/keys";

export const depositHandlerModule = buildModule("DepositHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { depositUtils } = m.useModule(depositUtilsModule)
    const { eventEmitter } = m.useModule(eventEmitterModule)

    const depositHandler = m.contract("DepositHandler", [roleStore, dataStore, eventEmitter], {
        libraries: {
            DepositUtils: depositUtils,
        },    
    });

    //m.call(roleStore, "grantRole",  [depositHandler, keys.CONTROLLER]);

    return { depositHandler };
});

export default depositHandlerModule;