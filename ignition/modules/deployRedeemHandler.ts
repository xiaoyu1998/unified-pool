import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { redeemUtilsModule } from "./deployRedeemUtils"
import { hashString } from "../../utils/hash";

export const redeemHandlerModule = buildModule("RedeemHandler", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { redeemUtils } = m.useModule(redeemUtilsModule)

    const redeemHandler = m.contract("RedeemHandler", [roleStore, dataStore], {
        libraries: {
            RedeemUtils: redeemUtils,
        },    
    });
    m.call(roleStore, "grantRole",  [redeemHandler, hashString("CONTROLLER")]);

    return { redeemHandler };
});

//export default redeemHandlerModule;