import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { swapUtilsModule } from "./deploySwapUtils"
import { repayUtilsModule } from "./deployRepayUtils"

export const repaySubstituteUtilsModule = buildModule("RepaySubstituteUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { swapUtils } = m.useModule(swapUtilsModule)
    const { repayUtils } = m.useModule(repayUtilsModule)

    const repaySubstituteUtils = m.library("RepaySubstituteUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            RepayUtils: repayUtils,
            SwapUtils: swapUtils,
        },      
    });

    return { repaySubstituteUtils };
});

export default repaySubstituteUtilsModule;