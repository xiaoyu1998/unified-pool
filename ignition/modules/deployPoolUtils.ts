import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const poolUtilsModule = buildModule("PoolUtils", (m) => {
    const poolUtils = m.contract("PoolUtils", []);

    return { poolUtils };
});

export default poolUtilsModule;