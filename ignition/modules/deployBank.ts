import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"

export const bankModule = buildModule("Bank", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const bank = m.contract("Bank", [roleStore, dataStore] );

    return { bank };
});

export default bankModule;