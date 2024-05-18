import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//import { feeUtilsModule } from "./deployFeeUtils"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { supplyEventUtilsModule } from "./deploySupplyEventUtils"
import { poolEventUtilsModule } from "./deployPoolEventUtils"

export const supplyUtilsModule = buildModule("SupplyUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { supplyEventUtils } = m.useModule(supplyEventUtilsModule)
    const { poolEventUtils } = m.useModule(poolEventUtilsModule)
 //   const { feeUtils } = m.useModule(feeUtilsModule)
    const supplyUtils = m.library("SupplyUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            SupplyEventUtils: supplyEventUtils,
            PoolEventUtils: poolEventUtils,
 //           FeeUtils: feeUtils
        },      
    });

    return { supplyUtils };
});

export default supplyUtilsModule;