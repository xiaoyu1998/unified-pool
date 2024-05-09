import { contractAt, sendTxn, getTokens, getContract, getContractAt, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getMarginsAndSupplies } from "../utils/helper";
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
    const supplyAmountUsdt = expandDecimals(8000000, usdtDecimals);
    await sendTxn(usdt.approve(router.target, supplyAmountUsdt), `usdt.approve(${router.target})`)  
    console.log("userUsdt",await usdt.balanceOf(owner.address), supplyAmountUsdt); 

    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);
    const supplyAmountUni = expandDecimals(800000, uniDecimals);
    await sendTxn(uni.approve(router.target, supplyAmountUni), `uni.approve(${router.target})`)  
    console.log("userUni",await uni.balanceOf(owner.address), supplyAmountUni); 

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
    //const tx = await exchangeRouter.multicall(multicallArgs);
    await sendTxn(
        exchangeRouter.multicall(multicallArgs),
        "exchangeRouter.multicall"
    );

    //print
    console.log("poolUsdtAfterSupply", await getPoolInfo(usdtAddress));
    console.log("account",await getMarginsAndSupplies(dataStore, reader, owner.address));
    console.log("poolUsdt",await usdt.balanceOf(poolUsdt.poolToken)); 
    console.log("poolUni",await uni.balanceOf(poolUni.poolToken)); 
    //console.log("allowance", await usdt.allowance(owner.address, router.target));

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })