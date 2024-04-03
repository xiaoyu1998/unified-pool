import { contractAt, sendTxn, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool, getLiquidity, getDebt} from "../utils/helper";

import { DepositUtils } from "../typechain-types/contracts/exchange/DepositHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");

    //execute borrows
    const usdtDecimals = 6;
    const usdtAddress = getTokens("USDT")["address"];
    console.log(usdtAddress);
    
    const poolUsdt = await getPool(usdtAddress); 
    const borrowAmmount = expandDecimals(1000, usdtDecimals);
    const params: DepositUtils.DepositParamsStruct = {
        underlyingAsset: usdtAddress,
        amount: borrowAmmount,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("executeDeposit", [params]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);  

    //print poolUsdt
    const poolToken = await getContractAt("PoolToken", poolUsdt.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdt.debtToken);
    console.log("poolUsdt", poolUsdt);
    console.log("poolToken",await getLiquidity(poolToken, owner.address));
    console.log("debtToken",await getDebt(debtToken, owner.address)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })