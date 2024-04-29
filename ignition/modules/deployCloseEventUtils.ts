import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const closeEventUtilsModule = buildModule("CloseEventUtils", (m) => {
    const closeEventUtils = m.contract("CloseEventUtils", []);

    return { closeEventUtils };
});

//export default poolUtilsModule;