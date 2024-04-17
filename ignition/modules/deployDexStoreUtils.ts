import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const dexStoreUtilsModule = buildModule("DexStoreUtils", (m) => {
    const dexStoreUtils = m.contract("DexStoreUtils", []);

    return { dexStoreUtils };
});

//export default roleStoreModule;