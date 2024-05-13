import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const supplyEventUtilsModule = buildModule("SupplyEventUtils", (m) => {
    const supplyEventUtils = m.contract("SupplyEventUtils", []);

    return { supplyEventUtils };
});

export default supplyEventUtilsModule;