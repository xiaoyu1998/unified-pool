import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const feeUtilsModule = buildModule("FeeUtils", (m) => {
    const feeUtils = m.contract("FeeUtils", []);

    return { feeUtils };
});

//export default roleStoreModule;