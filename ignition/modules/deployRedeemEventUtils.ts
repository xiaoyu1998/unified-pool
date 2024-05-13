import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const redeemEventUtilsModule = buildModule("RedeemEventUtils", (m) => {
    const redeemEventUtils = m.contract("RedeemEventUtils", []);

    return { redeemEventUtils };
});

export default redeemEventUtilsModule;