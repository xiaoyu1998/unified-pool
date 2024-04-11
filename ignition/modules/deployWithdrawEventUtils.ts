import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const withdrawEventUtilsModule = buildModule("WithdrawEventUtils", (m) => {
    const withdrawEventUtils = m.contract("WithdrawEventUtils", []);

    return { withdrawEventUtils };
});

//export default poolUtilsModule;