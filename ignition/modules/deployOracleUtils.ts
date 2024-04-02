import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { oracleStoreUtilsModule } from "./deployOracleStoreUtils"

export const oracleUtilsModule = buildModule("OracleUtils", (m) => {
    const { oracleStoreUtils } = m.useModule(oracleStoreUtilsModule);
    const oracleUtils = m.contract("OracleUtils", [], {
        libraries: {
            OracleStoreUtils: oracleStoreUtils,
        },        
    });

    return { oracleUtils };
});

//export default roleModule;