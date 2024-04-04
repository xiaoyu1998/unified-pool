import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { readerUtilsModule } from "./deployReaderUtils"

export const readerModule = buildModule("Reader", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule);
    const { oracleUtils } = m.useModule(oracleUtilsModule);
    const { readerUtils } = m.useModule(readerUtilsModule);

    const reader = m.contract("Reader", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleUtils: oracleUtils,
            ReaderUtils: readerUtils,
        }, 
    });

    return { reader };
});

// export default readerModule;