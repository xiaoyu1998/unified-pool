import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { feeUtilsModule } from "./deployFeeUtils"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"

export const supplyUtilsModule = buildModule("SupplyUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { feeUtils } = m.useModule(feeUtilsModule)
    const supplyUtils = m.library("SupplyUtils", {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            FeeUtils: feeUtils
        },      
    });

    return { supplyUtils };
});

// export default supplyHandlerModule;