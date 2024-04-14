import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const uniswapV3CalleeModule = buildModule("UniswapV3Callee", (m) => {
    const uniswapV3Callee = m.contract("UniswapV3Callee", []);

    return { uniswapV3Callee };
});

//export default poolUtilsModule;