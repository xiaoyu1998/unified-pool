import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const multicallModule = buildModule("Multicall3", (m) => {
    const multicall = m.contract("Multicall3", []);

    return { multicall };
});

//export default roleStoreModule;