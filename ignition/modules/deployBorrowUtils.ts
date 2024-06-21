import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { borrowEventUtilsModule } from "./deployBorrowEventUtils"
import { poolEventUtilsModule } from "./deployPoolEventUtils"

export const borrowUtilsModule = buildModule("BorrowUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { oracleUtils } = m.useModule(oracleUtilsModule)
    const { borrowEventUtils } = m.useModule(borrowEventUtilsModule)
    const { poolEventUtils } = m.useModule(poolEventUtilsModule)

    const borrowUtils = m.library("BorrowUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleUtils: oracleUtils,
            BorrowEventUtils: borrowEventUtils,
            PoolEventUtils: poolEventUtils,
        },      
    });

    return { borrowUtils };
});

export default borrowUtilsModule;