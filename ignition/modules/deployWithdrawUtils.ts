import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//import { feeUtilsModule } from "./deployFeeUtils"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { withdrawEventUtilsModule } from "./deployWithdrawEventUtils"

export const withdrawUtilsModule = buildModule("WithdrawUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { withdrawEventUtils } = m.useModule(withdrawEventUtilsModule)
//    const { feeUtils } = m.useModule(feeUtilsModule)
    const withdrawUtils = m.library("WithdrawUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            WithdrawEventUtils: withdrawEventUtils,
//            FeeUtils: feeUtils
        },      
    });

    return { withdrawUtils };
});

// export default withdrawHandlerModule;