import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"

export const dataStoreModule = buildModule("DataStore", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const dataStore = m.contract("DataStore", [roleStore] );

    return { dataStore };
});

export default dataStoreModule;