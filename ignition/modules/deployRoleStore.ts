import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const roleStoreModule = buildModule("RoleStore", (m) => {
    const roleStore = m.contract("RoleStore", []);

    return { roleStore };
});

//export default roleStoreModule;