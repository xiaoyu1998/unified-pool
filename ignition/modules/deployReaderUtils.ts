import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const readerUtilsModule = buildModule("ReaderUtils", (m) => {
    const readerUtils = m.contract("ReaderUtils", []);

    return { readerUtils };
});

//export default readerUtilsModule;