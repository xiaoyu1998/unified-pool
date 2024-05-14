import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { dexStoreUtilsModule } from "./deployDexStoreUtils"

export const readerDexUtilsModule = buildModule("ReaderDexUtils", (m) => {
    const { dexStoreUtils } = m.useModule(dexStoreUtilsModule);

    const readerDexUtils = m.contract("ReaderDexUtils", [], {
        libraries: {
            DexStoreUtils: dexStoreUtils,
        },
    });

    return { readerDexUtils };
});

export default readerDexUtilsModule;