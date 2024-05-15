import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
//import { feeUtilsModule } from "./deployFeeUtils"
//import { configStoreUtilsModule } from "./deployConfigStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { dexStoreUtilsModule } from "./deployDexStoreUtils"
import { swapEventUtilsModule } from "./deploySwapEventUtils"

export const swapUtilsModule = buildModule("SwapUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
 //   const { feeUtils } = m.useModule(feeUtilsModule)
 //   const { configStoreUtils } = m.useModule(configStoreUtilsModule)
    const { oracleUtils } = m.useModule(oracleUtilsModule)
    const { dexStoreUtils } = m.useModule(dexStoreUtilsModule);
    const { swapEventUtils } = m.useModule(swapEventUtilsModule)

    const swapUtils = m.library("SwapUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
 //           FeeUtils: feeUtils,
 //           ConfigStoreUtils: configStoreUtils,
            OracleUtils: oracleUtils,
            DexStoreUtils: dexStoreUtils,
            SwapEventUtils: swapEventUtils,
        },      
    });

    return { swapUtils };
});

export default swapUtilsModule;