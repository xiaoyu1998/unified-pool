import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { configStoreUtilsModule } from "./deployConfigStoreUtils"
import { oracleUtilsModule } from "./deployOracleUtils"
import { dexStoreUtilsModule } from "./deployDexStoreUtils"
import { liquidationEventUtilsModule } from "./deployLiquidationEventUtils"

export const liquidationUtilsModule = buildModule("LiquidationUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { configStoreUtils } = m.useModule(configStoreUtilsModule)
    const { oracleUtils } = m.useModule(oracleUtilsModule)
    const { liquidationEventUtils } = m.useModule(liquidationEventUtilsModule)

    const liquidationUtils = m.library("LiquidationUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            ConfigStoreUtils: configStoreUtils,
            OracleUtils: oracleUtils,
            LiquidationEventUtils: liquidationEventUtils,
        },      
    });

    return { liquidationUtils };
});

// export default liquidationHandlerModule;