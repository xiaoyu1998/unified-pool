import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const positionStoreUtilsModule = buildModule("PositionStoreUtils", (m) => {
    const positionStoreUtils = m.contract("PositionStoreUtils", []);

    return { positionStoreUtils };
});

//export default roleStoreModule;