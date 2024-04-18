import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const swapEventUtilsModule = buildModule("SwapEventUtils", (m) => {
    const swapEventUtils = m.contract("SwapEventUtils", []);

    return { swapEventUtils };
});

//export default poolUtilsModule;