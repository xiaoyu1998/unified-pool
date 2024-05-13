import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { configStoreUtilsModule } from "./deployConfigStoreUtils"

export const readerUtilsModule = buildModule("ReaderUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule);
    const { oracleUtils } = m.useModule(oracleUtilsModule);
    const { configStoreUtils } = m.useModule(configStoreUtilsModule);
    const readerUtils = m.contract("ReaderUtils", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleUtils: oracleUtils,
            ConfigStoreUtils: configStoreUtils,
        }, 
    });
    return { readerUtils };
});

export default readerUtilsModule;