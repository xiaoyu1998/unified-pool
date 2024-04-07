import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//import { feeUtilsModule } from "./deployFeeUtils"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"

export const withdrawUtilsModule = buildModule("WithdrawUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
//    const { feeUtils } = m.useModule(feeUtilsModule)
    const withdrawUtils = m.library("WithdrawUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
//            FeeUtils: feeUtils
        },      
    });

    return { withdrawUtils };
});

// export default withdrawHandlerModule;