import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { repayEventUtilsModule } from "./deployRepayEventUtils"
import { poolEventUtilsModule } from "./deployPoolEventUtils"

export const repayUtilsModule = buildModule("RepayUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { repayEventUtils } = m.useModule(repayEventUtilsModule)
    const { poolEventUtils } = m.useModule(poolEventUtilsModule)

    const repayUtils = m.library("RepayUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            RepayEventUtils: repayEventUtils,
            PoolEventUtils: poolEventUtils,
        },      
    });

    return { repayUtils };
});

export default repayUtilsModule;