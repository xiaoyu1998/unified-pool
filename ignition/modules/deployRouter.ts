import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"

export const routerModule = buildModule("Router", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const router = m.contract("Router", [roleStore] );

    return { router };
});

//export default routerModule;