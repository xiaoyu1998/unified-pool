import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const liquidationEventUtilsModule = buildModule("LiquidationEventUtils", (m) => {
    const liquidationEventUtils = m.contract("LiquidationEventUtils", []);

    return { liquidationEventUtils };
});

//export default poolUtilsModule;