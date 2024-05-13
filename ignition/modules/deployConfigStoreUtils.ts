import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const configStoreUtilsModule = buildModule("ConfigStoreUtils", (m) => {
    const configStoreUtils = m.contract("ConfigStoreUtils", []);

    return { configStoreUtils };
});

export default configStoreUtilsModule;