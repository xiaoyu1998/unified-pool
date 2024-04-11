import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"

export const eventEmitterModule = buildModule("EventEmitter", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const eventEmitter = m.contract("EventEmitter", [roleStore] );

    return { eventEmitter };
});

//export default dataStoreModule;