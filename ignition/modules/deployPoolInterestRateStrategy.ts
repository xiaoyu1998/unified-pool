import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { hashString } from "../../utils/hash";
import { bigNumberify, expandDecimals } from "../../utils/math";

export const poolInterestRateStrategyModule = buildModule("PoolInterestRateStrategy", (m) => {
    const optimalUsageRatio = expandDecimals(8, 26);//80%
    const rateBase = expandDecimals(0, 26);//0
    const rateSlope1 = expandDecimals(5, 26);//50%
    const rateSlope2 = expandDecimals(5, 26);//50%

    const poolInterestRateStrategy = m.contract("PoolInterestRateStrategy", [
        optimalUsageRatio,
        rateBase,
        rateSlope1,
        rateSlope2
    ]);
    
    return { poolInterestRateStrategy };
});

export default poolInterestRateStrategyModule;