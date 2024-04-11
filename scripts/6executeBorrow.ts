import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts, getPositions} from "../utils/helper";

import { BorrowUtils } from "../typechain-types/contracts/exchange/BorrowHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Borrow", (pool, borrower, to, amount) =>{
        console.log("eventEmitter Borrow" ,pool, borrower, to, amount);
    }); 

    //execute borrows
    const usdtDecimals = 6;
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);

    const borrowAmmount = expandDecimals(1000, usdtDecimals);
    const params: BorrowUtils.BorrowParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: borrowAmmount,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeBorrow", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolUsdt = await getPoolInfo(usdtAddress); 
    const poolToken = await getContractAt("PoolToken", poolUsdt.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdt.debtToken);
    console.log("poolUsdt", poolUsdt);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("positions",await getPositions(dataStore, reader, owner.address)); 
    console.log("userUSDT",await usdt.balanceOf(owner.address)); 
    console.log("poolUSDT",await usdt.balanceOf(poolToken.target)); 
    // console.log("price",await reader.getPrice(dataStore, usdtAddress)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })