import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { supplyUtilsModule } from "./deploySupplyUtils"
import { eventEmitterModule } from "./deployEventEmitter"
// import { hashString } from "../../utils/hash";
// import * as keys from "../../utils/keys";

export const supplyHandlerModule = buildModule("SupplyHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { eventEmitter } = m.useModule(eventEmitterModule)
    const { supplyUtils } = m.useModule(supplyUtilsModule)

    const supplyHandler = m.contract("SupplyHandler", [roleStore, dataStore, eventEmitter], {
        libraries: {
            SupplyUtils: supplyUtils,
        },    
    });
    // m.call(roleStore, "grantRole",  [supplyHandler, keys.CONTROLLER]);

    return { supplyHandler };
});

//export default supplyHandlerModule;