import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { withdrawUtilsModule } from "./deployWithdrawUtils"
import { hashString } from "../../utils/hash";

export const withdrawHandlerModule = buildModule("WithdrawHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { withdrawUtils } = m.useModule(withdrawUtilsModule)

    const withdrawHandler = m.contract("WithdrawHandler", [roleStore, dataStore], {
        libraries: {
            WithdrawUtils: withdrawUtils,
        },    
    });
    m.call(roleStore, "grantRole",  [withdrawHandler, hashString("CONTROLLER")]);

    return { withdrawHandler };
});

// export default withdrawHandlerModule;