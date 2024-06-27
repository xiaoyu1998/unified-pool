import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getMarginsAndSupplies, getPositions, getPositionsInfo, getLiquidationHealthFactor} from "../utils/helper";
import { BorrowUtils } from "../typechain-types/contracts/exchange/BorrowHandler";
import { getErrorMsgFromTx } from "../utils/error";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Borrow", (pool, borrower, to, amount, collateral, debtScaled) =>{
        console.log("eventEmitter Borrow" ,pool, borrower, to, amount, collateral, debtScaled);
    }); 

    //const config = await getContract("Config");
    // await sendTxn(
    //     config.setHealthFactorLiquidationThreshold(expandDecimals(110, 25)),//for liquidationTest
    //     "config.setHealthFactorLiquidationThreshold"
    // );
    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uni = await contractAt("MintableToken", uniAddress);

    //borrow usdt
    const borrowAmmountUsdt = expandDecimals(1, usdtDecimals);
    const paramsUsdt: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: borrowAmmountUsdt,
    };
    
    //borrow uni
    const borrowAmmountUni = expandDecimals(100000, uniDecimals);
    const paramsUni: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: uniAddress,
        amount: borrowAmmountUni,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [paramsUni]),
    ];
    // try {
    //     const tx = await exchangeRouter.multicall.staticCall(multicallArgs, {gasLimit:3000000});
    // } catch(err){
    //     console.log("Error:", getErrorMsg(err.data));
    // }
    try {
        await sendTxn(
            exchangeRouter.multicall(multicallArgs, {
                gasLimit:3000000,
            }),
            "exchangeRouter.multicall"
        );
    } catch(err) {
        console.log("Error:", await getErrorMsgFromTx(err.receipt.hash));
    }

    //print poolUsdt
    const poolUsdt = await getPoolInfo(usdtAddress); 
    const poolUni = await getPoolInfo(uniAddress); 
    console.log("poolUsdt", poolUsdt);
    console.log("poolUni", poolUni);
    console.log("marginsAndSupplies",await getMarginsAndSupplies(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("positionsInfo",await getPositionsInfo(dataStore, reader, owner.address)); 
    console.log("poolUsdt",await usdt.balanceOf(poolUsdt.poolToken)); 
    console.log("poolUni",await uni.balanceOf(poolUni.poolToken)); 
    // console.log("price",await reader.getPrice(dataStore, usdtAddress)); 
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })