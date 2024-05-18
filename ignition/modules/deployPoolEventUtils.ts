import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const poolEventUtilsModule = buildModule("PoolEventUtils", (m) => {
    const poolEventUtils = m.contract("PoolEventUtils", []);

    return { poolEventUtils };
});

export default poolEventUtilsModule;