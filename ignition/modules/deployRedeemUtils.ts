import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { redeemEventUtilsModule } from "./deployRedeemEventUtils"

export const redeemUtilsModule = buildModule("RedeemUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { oracleUtils } = m.useModule(oracleUtilsModule)
    const { redeemEventUtils } = m.useModule(redeemEventUtilsModule)

    const redeemUtils = m.library("RedeemUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            OracleUtils: oracleUtils,
            RedeemEventUtils: redeemEventUtils,
        },      
    });

    return { redeemUtils };
});

export default redeemUtilsModule;