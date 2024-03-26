import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
//import { feeUtilsModule } from "./deployFeeUtils"

export const depositUtilsModule = buildModule("DepositUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    //const { feeUtils } = m.useModule(feeUtilsModule)
    const depositUtils = m.library("DepositUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
  //          FeeUtils: feeUtils
        },      
    });

    return { depositUtils };
});

// export default depositHandlerModule;