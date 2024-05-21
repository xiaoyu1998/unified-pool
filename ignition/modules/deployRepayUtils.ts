import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { repayEventUtilsModule } from "./deployRepayEventUtils"
import { poolEventUtilsModule } from "./deployPoolEventUtils"
import { oracleUtilsModule } from "./deployOracleUtils"

export const repayUtilsModule = buildModule("RepayUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { repayEventUtils } = m.useModule(repayEventUtilsModule)
    const { poolEventUtils } = m.useModule(poolEventUtilsModule)
    const { oracleUtils } = m.useModule(oracleUtilsModule)

    const repayUtils = m.library("RepayUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            RepayEventUtils: repayEventUtils,
            PoolEventUtils: poolEventUtils,
            OracleUtils: oracleUtils,
        },      
    });

    return { repayUtils };
});

export default repayUtilsModule;