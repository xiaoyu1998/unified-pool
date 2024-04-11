import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
//import { feeUtilsModule } from "./deployFeeUtils"
import { depositEventUtilsModule } from "./deployDepositEventUtils"

export const depositUtilsModule = buildModule("DepositUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { depositEventUtils } = m.useModule(depositEventUtilsModule)
    //const { feeUtils } = m.useModule(feeUtilsModule)
    const depositUtils = m.library("DepositUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            DepositEventUtils: depositEventUtils,
  //          FeeUtils: feeUtils
        },      
    });

    return { depositUtils };
});

// export default depositHandlerModule;