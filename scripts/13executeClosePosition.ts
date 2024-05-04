import { contractAt, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions} from "../utils/helper";
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

    const uniDecimals = getTokens("UNI")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);

    // //deposit uni 200,000 
    const depositAmmountUni = expandDecimals(200000, uniDecimals);
    await uni.approve(router.target, depositAmmountUni);
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
    };     

    //close Position
    const params: CloseUtils.ClosePositionParamsStruct = {
        underlyingAsset: uniAddress,
        underlyingAssetUsd: usdtAddress
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [uniAddress, poolUni.poolToken, depositAmmountUni]),
        exchangeRouter.interface.encodeFunctionData("executeDeposit", [paramsUni]),
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsBorrow]),   
        exchangeRouter.interface.encodeFunctionData("executeSwap", [paramsSwap]),       
        exchangeRouter.interface.encodeFunctionData("executeClosePosition", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);

    //print 
    const poolUsdtAfterClosePosition = await getPoolInfo(usdtAddress); 
    const poolUniAfterClosePosition = await getPoolInfo(uniAddress); 
    console.log("poolUsdtAfterClosePosition", poolUsdtAfterClosePosition);
    console.log("poolUniAfterClosePosition", poolUniAfterClosePosition);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })