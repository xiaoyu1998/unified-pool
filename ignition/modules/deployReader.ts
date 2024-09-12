import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { oracleStoreUtilsModule } from "./deployOracleStoreUtils"
import { readerDexUtilsModule } from "./deployReaderDexUtils"
import { readerPositionUtilsModule } from "./deployReaderPositionUtils"
import { dexStoreUtilsModule } from "./deployDexStoreUtils"

export const readerModule = buildModule("Reader", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule);
    const { dexStoreUtils } = m.useModule(dexStoreUtilsModule);
    const { oracleUtils } = m.useModule(oracleUtilsModule);
    const { readerDexUtils } = m.useModule(readerDexUtilsModule);
    const { readerPositionUtils } = m.useModule(readerPositionUtilsModule);
    const { oracleStoreUtils } = m.useModule(oracleStoreUtilsModule);

    const reader = m.contract("Reader", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleUtils: oracleUtils,
            OracleStoreUtils: oracleStoreUtils,
            ReaderDexUtils: readerDexUtils,
            ReaderPositionUtils: readerPositionUtils,
        }, 
    });

    return { reader, poolStoreUtils, positionStoreUtils, dexStoreUtils };
});

export default readerModule;