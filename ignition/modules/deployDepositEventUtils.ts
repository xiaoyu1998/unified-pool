import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const depositEventUtilsModule = buildModule("DepositEventUtils", (m) => {
    const depositEventUtils = m.contract("DepositEventUtils", []);

    return { depositEventUtils };
});

//export default poolUtilsModule;