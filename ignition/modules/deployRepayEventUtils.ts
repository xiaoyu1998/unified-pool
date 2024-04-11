import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const repayEventUtilsModule = buildModule("RepayEventUtils", (m) => {
    const repayEventUtils = m.contract("RepayEventUtils", []);

    return { repayEventUtils };
});

//export default poolUtilsModule;