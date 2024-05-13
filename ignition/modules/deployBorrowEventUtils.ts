import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const borrowEventUtilsModule = buildModule("BorrowEventUtils", (m) => {
    const borrowEventUtils = m.contract("BorrowEventUtils", []);

    return { borrowEventUtils };
});

export default borrowEventUtilsModule;