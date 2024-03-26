import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const poolStoreUtilsModule = buildModule("PoolStoreUtils", (m) => {
    const poolStoreUtils = m.contract("PoolStoreUtils", []);

    return { poolStoreUtils };
});

//export default roleStoreModule;