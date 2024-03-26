import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { withdrawUtilsModule } from "./deployWithdrawUtils"

export const withdrawHandlerModule = buildModule("WithdrawHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { withdrawUtils } = m.useModule(withdrawUtilsModule)

    const withdrawHandler = m.contract("WithdrawHandler", [roleStore, dataStore], {
        libraries: {
            WithdrawUtils: withdrawUtils,
        },    
    });

    return { withdrawHandler };
});

// export default withdrawHandlerModule;