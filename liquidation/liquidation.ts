import { contractAt, sendTxn, getTokens, getContract, getEventEmitter} from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool, parsePool } from "../utils/helper";

async function main() {
    const accounts = await ethers.getSigners();
    const owner = accounts[0];
    const users = accounts.slice(1);

    //transfer usdt and eth
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const amountUsdt = expandDecimals(100000, usdtDecimals);

    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);
    const amountUni = expandDecimals(10000, uniDecimals);
 
    //console.log("accounts", accounts); 
    console.log("owner usdt", await usdt.balanceOf(owner)); 
    console.log("owner uni", await uni.balanceOf(owner)); 

    //transfer usdt and eth
    for (const user of users) {
        const amountEth = expandDecimals(1, 18);
        await sendTxn(
            usdt.transfer(user, amountUsdt), `usdt.transfer(${user.address} ${amountUsdt})`
        );
         await sendTxn(
            uni.transfer(user, amountUni), `uni.transfer(${user.address} ${amountUni})`
        );
        await sendTxn(
            owner.sendTransaction({to:user, value:amountEth}), `owner.transfer(${user.address} ${amountEth})`
        );
    };

    // //init contracts
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Borrow", (pool, borrower, amount, borrowRate, collateral, debtScaled) =>{
        const event: BorrowEvent.OutputTuple = {
            pool: pool,
            borrower: borrower,
            account: account,
            amount: amount,
            borrowRate: borrowRate,
            collateral: collateral,
            debtScaled: debtScaled
        };        
        console.log("eventEmitter Borrow" ,event);
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
        const borrowAmmountUsdt = expandDecimals(10000, usdtDecimals);
        const paramsBorrowUsdt: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: usdtAddress,
            amount: borrowAmmountUsdt,
        };

        //borrow uni
        const borrowAmmountUni = expandDecimals(1000, uniDecimals);
        const paramsUni: BorrowUtils.BorrowParamsStruct = {
            underlyingAsset: uniAddress,
            amount: borrowAmmountUni,
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

    console.log("owner usdt", await usdt.balanceOf(owner)); 
    console.log("owner uni", await uni.balanceOf(owner)); 

    const pools = await reader.getPools(dataStore.target);
    for (const pool of pools) {
        console.log(parsePool(pool));
    }

    // const config = await getContract("Config");
    // await sendTxn(
    //     config.setHealthFactorLiquidationThreshold(expandDecimals(400, 25)),//400%
    //     "config.setHealthFactorLiquidationThreshold"
    // );

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })