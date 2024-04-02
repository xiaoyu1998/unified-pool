import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleStoreUtilsModule } from "./deployOracleStoreUtils"

export const readerModule = buildModule("Reader", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule);
    const { oracleStoreUtils } = m.useModule(oracleStoreUtilsModule);

    const reader = m.contract("Reader", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleStoreUtils: oracleStoreUtils,
        }, 
    });

    return { reader };
});

// export default readerModule;