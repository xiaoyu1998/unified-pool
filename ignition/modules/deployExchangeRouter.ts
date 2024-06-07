import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { routerModule } from "./deployRouter"
import { roleStoreModule } from "./deployRoleStore"
import { dataStoreModule } from "./deployDataStore"
import { supplyHandlerModule } from "./deploySupplyHandler"
import { withdrawHandlerModule } from "./deployWithdrawHandler"
import { depositHandlerModule } from "./deployDepositHandler"
import { borrowHandlerModule } from "./deployBorrowHandler"
import { repayHandlerModule } from "./deployRepayHandler"
import { redeemHandlerModule } from "./deployRedeemHandler"
import { swapHandlerModule } from "./deploySwapHandler"
import { liquidationHandlerModule } from "./deployLiquidationHandler"
import { closeHandlerModule } from "./deployCloseHandler"

import { configModule } from "./deployConfig"
import { poolFactoryModule } from "./deployPoolFactory"
import { poolInterestRateStrategyModule } from "./deployPoolInterestRateStrategy"
import { poolStoreUtilsModule } from "./deployPoolStoreUtils"
import { readerModule } from "./deployReader"
import { multicallModule } from "./deployMulticall"
import { bankModule } from "./deployBank"
import { eventEmitterModule } from "./deployEventEmitter"

import { positionStoreUtilsModule } from "./deployPositionStoreUtils"
import { oracleStoreUtilsModule } from "./deployOracleStoreUtils"
import { dexStoreUtilsModule } from "./deployDexStoreUtils"

import { hashString } from "../../utils/hash";
import * as keys from "../../utils/keys";

export const exchangeRouterModule = buildModule("ExchangeRouter", (m) => {
    const { router } = m.useModule(routerModule);
    const { roleStore } = m.useModule(roleStoreModule);
    const { dataStore } = m.useModule(dataStoreModule);
    const { supplyHandler } = m.useModule(supplyHandlerModule);
    const { withdrawHandler } = m.useModule(withdrawHandlerModule);
    const { depositHandler } = m.useModule(depositHandlerModule);
    const { borrowHandler } = m.useModule(borrowHandlerModule);
    const { repayHandler } = m.useModule(repayHandlerModule);
    const { redeemHandler } = m.useModule(redeemHandlerModule);
    const { swapHandler } = m.useModule(swapHandlerModule);
    const { liquidationHandler } = m.useModule(liquidationHandlerModule);
    const { closeHandler } = m.useModule(closeHandlerModule);
    const { config } = m.useModule(configModule);
    const { poolFactory } = m.useModule(poolFactoryModule); 
    const { poolInterestRateStrategy } = m.useModule(poolInterestRateStrategyModule) ;  
    const { reader } = m.useModule(readerModule);
    const { multicall } = m.useModule(multicallModule);
    const { bank } = m.useModule(bankModule);
    const { eventEmitter } = m.useModule(eventEmitterModule)
    const { poolStoreUtils } = m.useModule(poolStoreUtilsModule)
    const { positionStoreUtils } = m.useModule(positionStoreUtilsModule)
    const { oracleStoreUtils } = m.useModule(oracleStoreUtilsModule)
    const { dexStoreUtils } = m.useModule(dexStoreUtilsModule)

    const exchangeRouter = m.contract("ExchangeRouter", [
        router,
        roleStore, 
        dataStore,
        supplyHandler,
        withdrawHandler, 
        depositHandler,
        borrowHandler,
        repayHandler, 
        redeemHandler,
        swapHandler,
        liquidationHandler,
        closeHandler
    ]);

    m.call(roleStore, "grantRole",  [supplyHandler, keys.CONTROLLER], {id:"grantRole1" });
    m.call(roleStore, "grantRole",  [withdrawHandler, keys.CONTROLLER], {id:"grantRole2"});
    m.call(roleStore, "grantRole",  [borrowHandler, keys.CONTROLLER], {id:"grantRole3"}); 
    m.call(roleStore, "grantRole",  [depositHandler, keys.CONTROLLER], {id:"grantRole4"}); 
    m.call(roleStore, "grantRole",  [repayHandler, keys.CONTROLLER], {id:"grantRole5"});
    m.call(roleStore, "grantRole",  [redeemHandler, keys.CONTROLLER], {id:"grantRole6"});
    m.call(roleStore, "grantRole",  [swapHandler, keys.CONTROLLER], {id:"grantRole7"});
    m.call(roleStore, "grantRole",  [liquidationHandler, keys.CONTROLLER], {id:"grantRole8"});
    m.call(roleStore, "grantRole",  [closeHandler, keys.CONTROLLER], {id:"grantRole9"});
    m.call(roleStore, "grantRole",  [poolFactory, keys.CONTROLLER], {id:"grantRole10"});
    m.call(roleStore, "grantRole",  [config, keys.CONTROLLER], {id:"grantRole11"});
    m.call(roleStore, "grantRole",  [exchangeRouter, keys.CONTROLLER], {id:"grantRole12"});
    m.call(roleStore, "grantRole",  [exchangeRouter, keys.ROUTER_PLUGIN], {id:"grantRole13"});
    return { 
        roleStore, 
        dataStore, 
        router, 
        exchangeRouter, 
        reader, 
        eventEmitter, 
        config,
        poolFactory,
        poolInterestRateStrategy,
        poolStoreUtils,
        positionStoreUtils,
        oracleStoreUtils,
        dexStoreUtils
    };
});

export default exchangeRouterModule;