import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { supplyUtilsModule } from "./deploySupplyUtils"

export const supplyHandlerModule = buildModule("SupplyHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { supplyUtils } = m.useModule(supplyUtilsModule)

    const supplyHandler = m.contract("SupplyHandler", [roleStore, dataStore], {
        libraries: {
            SupplyUtils: supplyUtils,
        },    
    });

    return { supplyHandler };
});

//export default supplyHandlerModule;