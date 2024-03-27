import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"

export const readerModule = buildModule("Reader", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const reader = m.contract("Reader", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils
        }, 
    });

    return { reader };
});

// export default readerModule;