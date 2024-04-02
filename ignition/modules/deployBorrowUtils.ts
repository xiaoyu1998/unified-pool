import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { feeUtilsModule } from "./deployFeeUtils"
import { configStoreUtilsModule } from "./deployConfigStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"

export const borrowUtilsModule = buildModule("BorrowUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { feeUtils } = m.useModule(feeUtilsModule)
    const { configStoreUtils } = m.useModule(configStoreUtilsModule)
    const { oracleUtils } = m.useModule(oracleUtilsModule)

    const borrowUtils = m.library("BorrowUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            FeeUtils: feeUtils,
            ConfigStoreUtils: configStoreUtils,
            OracleUtils: oracleUtils
        },      
    });

    return { borrowUtils };
});

// export default borrowHandlerModule;