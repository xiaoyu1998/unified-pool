import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const oracleStoreUtilsModule = buildModule("OracleStoreUtils", (m) => {
    const oracleStoreUtils = m.contract("OracleStoreUtils", []);

    return { oracleStoreUtils };
});

//export default roleStoreModule;