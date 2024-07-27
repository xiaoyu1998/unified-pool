import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { oracleStoreUtilsModule } from "./deployOracleStoreUtils"
import { dexStoreUtilsModule } from "./deployDexStoreUtils"
import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { feeStoreUtilsModule } from "./deployFeeStoreUtils"


export const configModule = buildModule("Config", (m) => {
    const { roleStore } = m.useModule(roleStoreModule);
    const { dataStore } = m.useModule(dataStoreModule);
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule);
    const { oracleStoreUtils } = m.useModule(oracleStoreUtilsModule);
    const { dexStoreUtils } = m.useModule(dexStoreUtilsModule);
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { feeStoreUtils } = m.useModule(feeStoreUtilsModule)


    const config = m.contract("Config", [roleStore, dataStore], {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            OracleStoreUtils: oracleStoreUtils,
            DexStoreUtils: dexStoreUtils,
            PositionStoreUtils: positionStoreUtils,
            FeeStoreUtils: feeStoreUtils
        },
    });
    // m.call(roleStore, "grantRole",  [config, keys.CONTROLLER]);

    return { config };
});

export default configModule;