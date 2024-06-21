import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { readerDexUtilsModule } from "./deployReaderDexUtils"
import { readerPositionUtilsModule } from "./deployReaderPositionUtils"

export const readerModule = buildModule("Reader", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule);
    const { oracleUtils } = m.useModule(oracleUtilsModule);
    const { readerDexUtils } = m.useModule(readerDexUtilsModule);
    const { readerPositionUtils } = m.useModule(readerPositionUtilsModule);

    const reader = m.contract("Reader", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleUtils: oracleUtils,
            ReaderDexUtils: readerDexUtils,
            ReaderPositionUtils: readerPositionUtils,
        }, 
    });

    return { reader };
});

export default readerModule;