import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { hashString } from "../../utils/hash";

export const roleStoreModule = buildModule("RoleStore", (m) => {
    const roleStore = m.contract("RoleStore", []);
    
    const account = m.getAccount(0);
    m.call(roleStore, "grantRole",  [account, hashString("CONFIG_KEEPER")], {
        id: "grantRole1"
    })
    m.call(roleStore, "grantRole",  [account, hashString("POOL_KEEPER")], {
        id: "grantRole2"
    } )

    return { roleStore };
});

export default roleStoreModule;