import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const poolUtilsModule = buildModule("PoolUtils", (m) => {
    const poolUtils = m.contract("PoolUtils", []);

    return { poolUtils };
});

//export default poolUtilsModule;