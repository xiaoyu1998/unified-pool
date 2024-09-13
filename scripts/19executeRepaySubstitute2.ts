import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals, bigNumberify } from "../utils/math";
import { getPoolInfo, getAssets,  getPositions, getMarginAndSupply} from "../utils/helper";
import { RepaytUtils } from "../typechain-types/contracts/exchange/RepaytHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  

    const usdtDecimals = getTokens("USDT")["decimals"];
    const uniDecimals = getTokens("UNI")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uni = await contractAt("MintableToken", uniAddress);

    const assetsBeforeRepay = await getAssets(dataStore, reader, owner.address);
    const uniBeforeRepay = await getMarginAndSupply(dataStore, reader, owner.address, uniAddress);
    const balanceUniBeforeRepay = await uni.balanceOf(owner.address);
    const poolUni = await getPoolInfo(uniAddress); 

    // transfer total uni debt+1 to repay all debt
    const repayAllDebtAmount = uniBeforeRepay.debt + expandDecimals(1, uniDecimals);
    await sendTxn(
        uni.approve(router.target, repayAllDebtAmount),
        "uni.approve"
    );
    const params: RepaytUtils.RepayParamsStruct = {
        underlyingAsset: uniAddress,
        amount: 0,
        substitute: uniAddress
    }; 
    const multicallArgs2 = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [uniAddress, poolUni.poolToken, repayAllDebtAmount]),
        exchangeRouter.interface.encodeFunctionData("executeRepaySubstitute", [params]),
    ];

    const estimatedGas = await exchangeRouter.multicall.estimateGas(multicallArgs2);
    console.log("estimatedGas", estimatedGas);
    
    await sendTxn(
        exchangeRouter.multicall(multicallArgs2),
        "exchangeRouter.multicall"
    );

    //print 
    console.log("assetsBeforeRepay", assetsBeforeRepay);
    console.log("assetsAfterRepay", await getAssets(dataStore, reader, owner.address));
    //console.log("positions", await getPositions(dataStore, reader, owner.address)); 
    console.log("balanceUniBeforeRepay", balanceUniBeforeRepay);
    console.log("uniBeforeRepay.debt", uniBeforeRepay.debt );
    console.log("repayAllDebtAmount", repayAllDebtAmount );
    console.log("balanceUniAfterRepay", await uni.balanceOf(owner.address));

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })