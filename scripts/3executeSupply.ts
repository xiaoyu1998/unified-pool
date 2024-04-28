import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidityAndDebts } from "../utils/helper";

import { SupplyUtils } from "../typechain-types/contracts/exchange/SupplyHandler";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const exchangeRouter = await getContract("ExchangeRouter"); 
    const router = await getContract("Router");
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const eventEmitter = await getEventEmitter();  
    eventEmitter.on("Supply", (pool, supplier, to, amount) =>{
        console.log("eventEmitter Supply" ,pool, supplier, to, amount);
    });

    //approve allowances to the router
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const supplyAmountUsdt = expandDecimals(8000, usdtDecimals);
    await sendTxn(usdt.approve(router.target, supplyAmountUsdt), `usdt.approve(${router.target})`)  

    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);
    const supplyAmountUni = expandDecimals(1000, uniDecimals);
    await sendTxn(uni.approve(router.target, supplyAmountUni), `uni.approve(${router.target})`)  

    //execute supply
    const poolUsdt = await getPoolInfo(usdtAddress); 
    const paramsUsdt: SupplyUtils.SupplyParamsStruct = {
        underlyingAsset: usdtAddress,
        to: owner.address,
    };
    const poolUni = await getPoolInfo(uniAddress); 
    const paramsUni: SupplyUtils.SupplyParamsStruct = {
        underlyingAsset: uniAddress,
        to: owner.address,
    };
    const multicallArgs = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdtAddress, poolUsdt.poolToken, supplyAmountUsdt]),
        exchangeRouter.interface.encodeFunctionData("executeSupply", [paramsUsdt]),
        exchangeRouter.interface.encodeFunctionData("sendTokens", [uniAddress, poolUni.poolToken, supplyAmountUni]),
        exchangeRouter.interface.encodeFunctionData("executeSupply", [paramsUni]),
    ];
    const tx = await exchangeRouter.multicall(multicallArgs);

    //print poolUsdt
    const poolUsdtAfterSupply = await getPoolInfo(usdtAddress); 
    const poolToken = await getContractAt("PoolToken", poolUsdtAfterSupply.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdtAfterSupply.debtToken);
    console.log("poolUsdtAfterSupply", poolUsdtAfterSupply);
    console.log("account",await getLiquidityAndDebts(dataStore, reader, owner.address));
    console.log("userUSDT",await usdt.balanceOf(owner.address)); 
    console.log("poolUSDT",await usdt.balanceOf(poolToken.target)); 
    //console.log("allowance", await usdt.allowance(owner.address, router.target));

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })