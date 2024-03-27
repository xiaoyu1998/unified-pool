import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { roleStoreModule } from "./deployRoleStore"
import { configModule } from "./deployConfig"
import { poolFactoryrModule } from "./deployPoolFactory"
import { exchangeRouterModule } from "./deployExchangeRouter"
import { poolInterestRateStrategyModule } from "./deployPoolInterestRateStrategy"
import { readerModule } from "./deployReader"
// import { dataStoreModule } from "./deployDataStore"
// import { borrowUtilsModule } from "./deployBorrowUtils"
import * as keys from "../../utils/keys";

const allModules = buildModule("All", (m) => {
    const { roleStore } = m.useModule(roleStoreModule)
    const { config } = m.useModule(configModule)
    const { poolFactory } = m.useModule(poolFactoryrModule)    
    const { exchangeRouter } = m.useModule(exchangeRouterModule)    
    const { poolInterestRateStrategy } = m.useModule(poolInterestRateStrategyModule)   
    const { reader } = m.useModule(readerModule) 
    
    m.call(roleStore, "grantRole",  [poolFactory, keys.CONTROLLER]);
    m.call(roleStore, "grantRole",  [config, keys.CONTROLLER]);

    return { exchangeRouter };
});

export default allModules;