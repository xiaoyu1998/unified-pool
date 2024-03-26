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

const exchangeRouterModule = buildModule("ExchangeRouter", (m) => {
    const { router } = m.useModule(routerModule)
    const { roleStore } = m.useModule(roleStoreModule)
    const { dataStore } = m.useModule(dataStoreModule)
    const { supplyHandler } = m.useModule(supplyHandlerModule)
    const { withdrawHandler } = m.useModule(withdrawHandlerModule)
    const { depositHandler } = m.useModule(depositHandlerModule)
    const { borrowHandler } = m.useModule(borrowHandlerModule)
    const { repayHandler } = m.useModule(repayHandlerModule)
    const { redeemHandler } = m.useModule(redeemHandlerModule)

    const exchangeRouter = m.contract("ExchangeRouter", [
        router,
        roleStore, 
        dataStore,
        supplyHandler,
        withdrawHandler, 
        depositHandler,
        borrowHandler,
        repayHandler, 
        redeemHandler
    ]);

    return { exchangeRouter };
});

export default exchangeRouterModule;