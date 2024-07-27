import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const feeStoreUtilsModule = buildModule("FeeStoreUtils", (m) => {
    const feeStoreUtils = m.contract("FeeStoreUtils", []);

    return { feeStoreUtils };
});

export default feeStoreUtilsModule;