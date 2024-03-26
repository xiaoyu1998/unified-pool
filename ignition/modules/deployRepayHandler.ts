import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { repayUtilsModule } from "./deployRepayUtils"

export const repayHandlerModule = buildModule("RepayHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { repayUtils } = m.useModule(repayUtilsModule)

    const repayHandler = m.contract("RepayHandler", [roleStore, dataStore], {
        libraries: {
            RepayUtils: repayUtils,
        },    
    });

    return { repayHandler };
});

//export default repayHandlerModule;