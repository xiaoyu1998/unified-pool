import { contractAt, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions} from "../utils/helper";
import { CloseUtils } from "../typechain-types/contracts/exchange/CloseHandler.sol/CloseHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const exchangeRouter = await getContract("ExchangeRouter"); 
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

    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];

    //execute close Position
    const params: CloseUtils.ClosePositionParamsStruct = {
        underlyingAsset: uniAddress,
        underlyingAssetUsd: usdtAddress
    };
    const multicallArgs = [
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