import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt } from "../utils/math";
import { getPoolInfo, getMarginsAndSupplies, getPositions, getPositionsInfo} from "../utils/helper";
import { CloseUtils } from "../typechain-types/contracts/exchange/CloseHandler.sol/CloseHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("ClosePosition", (underlyingAsset, underlyingAssetUsd, account, collateralAmount, debtAmount, remainAmountUsd) => {
        const event: ClosePositionEvent.OutputTuple = {
            underlyingAsset: underlyingAsset,
            underlyingAssetUsd: underlyingAssetUsd,
            account: account,
            collateralAmount: collateralAmount,
            debtAmount: debtAmount,
            remainAmountUsd: remainAmountUsd
        };        
        console.log("eventEmitter ClosePosition" ,event);
    });

    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);

    // //deposit usdt 200,000 
    const depositAmmountUsdt = expandDecimals(200000, usdtDecimals);
    await sendTxn(
        usdt.approve(router.target, depositAmmountUsdt),
        "usdt.approve"
    );

    const poolUsdt = await getPoolInfo(usdtAddress); 
    const paramsUsdt: DepositUtils.DepositParamsStruct = {
        underlyingAsset: usdtAddress,
    };

    //borrow usdt 100,000
    const borrowAmmount = expandDecimals(100000, usdtDecimals);
    const paramsBorrow: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: borrowAmmount,
    };   

    const params: CloseUtils.ClosePositionParamsStruct = {
        underlyingAsset: usdtAddress,
        underlyingAssetUsd: usdtAddress
    };
    let multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolUsdt.poolToken, depositAmmountUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeDeposit", [paramsUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsBorrow]),        
    ];
    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    console.log("account",await getMarginsAndSupplies(dataStore, reader, owner.address));

    //close Position
    multicallArgs = [      
        exchangeRouter.interface.encodeFunctionData("executeClosePosition", [params]),
    ];
    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    //print 
    console.log("Assets",await getMarginsAndSupplies(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })