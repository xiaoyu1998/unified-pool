import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt } from "../utils/math";
import { getPoolInfo, getAssets, getPositions, getPositionsInfo} from "../utils/helper";
import { ClosePositionEvent } from "../typechain-types/contracts/event/EventEmitter.ts";

async function main() {
    const [owner] = await ethers.getSigners();

    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("ClosePosition", (pool, poolUsd, account, collateralSold, debtClosed, remainCollateral, remainUsd, collateralUsd, debtScaledUsd) => {
        const event: ClosePositionEvent.OutputTuple = {
            pool: pool,
            poolUsd: poolUsd,
            account: account,
            collateralSold: collateralSold,
            debtClosed: debtClosed,
            remainCollateral: remainCollateral,
            remainUsd: remainUsd,
            collateralUsd: collateralUsd,
            debtScaledUsd: debtScaledUsd
        };        
        console.log("eventEmitter ClosePosition", event);
    });

    const uniDecimals = getTokens("UNI")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);

    // //deposit uni 200,000 
    const depositAmmountUni = expandDecimals(200000, uniDecimals);
    await sendTxn(
        uni.approve(router.target, depositAmmountUni),
        "uni.approve"
    );

    const poolUni = await getPoolInfo(uniAddress); 
    const paramsUni: DepositUtils.DepositParamsStruct = {
        underlyingAsset: uniAddress,
    };

    //short uni 100,000
    const borrowAmmount = expandDecimals(100000, uniDecimals);
    const paramsBorrow: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: uniAddress,
        amount: borrowAmmount,
    };
    const paramsSwap: SwapUtils.SwapParamsStruct = {
        underlyingAssetIn: uniAddress,
        underlyingAssetOut: usdtAddress,
        amount: borrowAmmount,
        sqrtPriceLimitX96: 0
    };     

    //close Position
    const params: CloseUtils.ClosePositionParamsStruct = {
        underlyingAsset: uniAddress,
        underlyingAssetUsd: usdtAddress,
        //percentage: expandDecimals(5, 26)//50%
        percentage: expandDecimals(1, 27)//100%
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [uniAddress, poolUni.poolToken, depositAmmountUni]),
        exchangeRouter.interface.encodeFunctionData("executeDeposit", [paramsUni]),
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsBorrow]),   
        exchangeRouter.interface.encodeFunctionData("executeSwap", [paramsSwap]),       
        exchangeRouter.interface.encodeFunctionData("executeClosePosition", [params]),
    ];
    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    //print 
    console.log("assets",await getAssets(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })