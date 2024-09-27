import { contractAt, sendTxn, getTokens, getContract, getEventEmitter, getDeployedContractAddress} from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { MaxUint256 } from "../utils/constants";
import { getPool, parsePool, getPositions, getAssets } from "../utils/helper";
import { LiquidationUtils } from "../typechain-types/contracts/exchange/LiquidationHandler";

async function main() {
    const accounts = await ethers.getSigners();
    const owner = accounts[0];
    const users = accounts.slice(1, 2);
    console.log("users", users); 

    // // //transfer usdt and eth
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const amountUsdt = expandDecimals(10000, usdtDecimals);

    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);
    const amountUni = expandDecimals(1000, uniDecimals);
 
    //console.log("accounts", accounts); 
    console.log("owner", owner.address);
    console.log("owner usdt", await usdt.balanceOf(owner)); 
    console.log("owner uni", await uni.balanceOf(owner)); 

    // //transfer usdt and eth
    for (const user of users) {
        const amountEth = expandDecimals(1, 18);
        await sendTxn(
            usdt.transfer(user, amountUsdt), `usdt.transfer(${user.address} ${amountUsdt})`
        );
         await sendTxn(
            uni.transfer(user, amountUni), `uni.transfer(${user.address} ${amountUni})`
        );
        // await sendTxn(
        //     owner.sendTransaction({to:user, value:amountEth}), `owner.transfer(${user.address} ${amountEth})`
        // );
    };

    console.log("owner after transfer usdt", await usdt.balanceOf(owner)); 
    console.log("owner after transfer uni", await uni.balanceOf(owner)); 


    // // //init contracts
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const liquidationHandler = await getDeployedContractAddress("LiquidationHandler");
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Liquidation", async (liquidator, account, healthFactor, healthFactorLiquidationThreshold, totalCollateralUsd, totalDebtUsd) => { 
        const event: LiquidationEvent.OutputTuple = {
            liquidator: liquidator,
            account: account,
            healthFactor: healthFactor,
            healthFactorLiquidationThreshold: healthFactorLiquidationThreshold,
            totalCollateralUsd: totalCollateralUsd,
            totalDebtUsd: totalDebtUsd
        };        
        console.log("eventEmitter Liquidation", event);
    });

    eventEmitter.on("LiquidationPosition", (liquidator, pool, account, collateralUsd, debtUsd) =>{
        const event: LiquidationPositionEvent.OutputTuple = {
            liquidator: liquidator,
            pool: pool,
            account: account,
            collateralUsd: collateralUsd,
            debtUsd: debtUsd
        };        
        console.log("eventEmitter LiquidationPosition" ,event);
    });
  
    //accounts init for liquidation
    for (const user of users) {
        await sendTxn(
            usdt.connect(user).approve(router.target, amountUsdt), `usdt.approve(${router.target} ${amountUsdt})`
        );
        //deposit usdt
        const paramsUsdt: DepositUtils.DepositParamsStruct = {
            underlyingAsset: usdtAddress,
        };

        //borrow usdt
        //const borrowAmmountUsdt = expandDecimals(10000, usdtDecimals);
        const paramsBorrowUsdt: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: usdtAddress,
            amount: amountUsdt,
        };

        //borrow uni
        //const borrowAmmountUni = expandDecimals(1000, uniDecimals);
        const paramsUni: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: uniAddress,
            amount: amountUni,
        };
        
        const poolUsdt = await getPool(usdtAddress); 
        const multicallArgs = [
            exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolUsdt.poolToken, amountUsdt]),
            exchangeRouter.interface.encodeFunctionData("executeDeposit", [paramsUsdt]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsBorrowUsdt]),
            exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsUni]),
        ];
        await sendTxn(
            exchangeRouter.connect(user).multicall(multicallArgs),
            "exchangeRouter.multicall"
        );
    };


    // const usdtDecimals = getTokens("USDT")["decimals"];
    // const usdtAddress = getTokens("USDT")["address"];
    // const usdt = await contractAt("MintableToken", usdtAddress);
    // const amount = expandDecimals(1000000, usdtDecimals);

    // const liquidator = "0xAA292E8611aDF267e563f334Ee42320aC96D0463";
    // await sendTxn(
    //     usdt.transfer(liquidator, amount), `usdt.transfer(${liquidator} ${amount})`
    // );
    // console.log("owner usdt", await usdt.balanceOf(liquidator)); 


    await sendTxn(
        usdt.approve(liquidationHandler, MaxUint256), `usdt.approve(${liquidationHandler} ${MaxUint256})`
    );
    await sendTxn(
        uni.approve(liquidationHandler, MaxUint256), `uni.approve(${liquidationHandler} ${MaxUint256})`
    );

    const config = await getContract("Config");
    await sendTxn(
        config.setHealthFactorLiquidationThreshold(expandDecimals(400, 25)),//400%
        "config.setHealthFactorLiquidationThreshold"
    );

    //
    let multicallArgs = [];
    for (const user of users) {
        //execute close Positions
        const paramsLiquidation: LiquidationUtils.LiquidationParamsStruct = {
            account: user.address
        };
        multicallArgs.push(exchangeRouter.interface.encodeFunctionData("executeLiquidation", [paramsLiquidation]))
    };

    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    for (const user of users) {
        console.log("assets", await getAssets(dataStore, reader, user.address));
        console.log("positions", await getPositions(dataStore, reader, user.address)); 
    };

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })