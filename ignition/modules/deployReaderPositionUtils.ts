import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"

export const readerPositionUtilsModule = buildModule("ReaderPositionUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule);
    const { oracleUtils } = m.useModule(oracleUtilsModule);
    const readerPositionUtils = m.contract("ReaderPositionUtils", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleUtils: oracleUtils,
        }, 
    });
    return { readerPositionUtils };
});

export default readerPositionUtilsModule;