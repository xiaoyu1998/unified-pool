import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions, getPositionsInfo} from "../utils/helper";
import { SwapUtils } from "../typechain-types/contracts/exchange/SwapHandler";

async function main() {
    const [owner] = await ethers.getSigners();

    const exchangeRouter = await getContract("ExchangeRouter"); 
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Swap", (underlyingAssetIn, underlyingAssetOut, account, amountIn, amountOut) =>{
        console.log("eventEmitter Swap" ,underlyingAssetIn, underlyingAssetOut, account, amountIn, amountOut);
    });

    const usdtDecimals = getTokens("USDT")["decimals"];
    const uniDecimals = getTokens("UNI")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uni = await contractAt("MintableToken", uniAddress);

    //borrow
    const borrowAmmount = expandDecimals(100000, uniDecimals);
    const paramsBorrow: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: uniAddress,
        amount: borrowAmmount,
    };

    //swap
    const paramsSwap: SwapUtils.SwapParamsStruct = {
        underlyingAssetIn: uniAddress,
        underlyingAssetOut: usdtAddress,
        amount: borrowAmmount,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsBorrow]),
        exchangeRouter.interface.encodeFunctionData("executeSwap", [paramsSwap]),
    ];
    // const tx = await exchangeRouter.multicall(multicallArgs, {
    //     gasLimit:2000000,
    // });
    await sendTxn(
        exchangeRouter.multicall(multicallArgs, {
            gasLimit:2000000,
        }),
        "exchangeRouter.multicall"
    );

    //print 
    const poolUsdtAfterSwap = await getPoolInfo(usdtAddress); 
    const poolUniAfterSwap = await getPoolInfo(uniAddress); 
    console.log("poolUsdtAfterSwap", poolUsdtAfterSwap);
    console.log("poolUniAfterSwap", poolUniAfterSwap);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("positionsInfo",await getPositionsInfo(dataStore, reader, owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })