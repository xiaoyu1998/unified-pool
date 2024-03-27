import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { hashString } from "../../utils/hash";
import { bigNumberify, expandDecimals } from "../../utils/math";

export const poolInterestRateStrategyModule = buildModule("PoolInterestRateStrategy", (m) => {
    const optimalUsageRatio = bigNumberify(8)*expandDecimals(1, 26);
    const rateSlope1 = bigNumberify(10)*expandDecimals(1, 26);
    const rateSlope2 = bigNumberify(5)*expandDecimals(1, 26);

    const poolInterestRateStrategy = m.contract("PoolInterestRateStrategy", [
        optimalUsageRatio,
        rateSlope1,
        rateSlope2
    ]);

    // const rateSlope1FromContract = m.staticCall(poolInterestRateStrategy, "getRateSlope1");
    // const rateSlope2FromContract = m.staticCall(poolInterestRateStrategy, "getRateSlope2");

    // console.log("rateSlope1",rateSlope1, "rateSlope2", rateSlope2);
    // console.log("rateSlope1",rateSlope1FromContract, "rateSlope2", rateSlope2FromContract);

    return { poolInterestRateStrategy };
});

//export default poolInterestRateStrategyModule;