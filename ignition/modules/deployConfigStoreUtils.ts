import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"

export const configStoreUtilsModule = buildModule("ConfigStoreUtils", (m) => {
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const configStoreUtils = m.contract("ConfigStoreUtils", [], {
        libraries: {
            PoolStoreUtils: poolStoreUtils
        }, 
    });

    return { configStoreUtils };
});

export default configStoreUtilsModule;