import { deployContract, deployContractWithCode, contractAtWithCode, getContract, sendTxn, writeTokenAddresses, readTokenAddresses, setDeployedContractAddress } from "../utils/deploy"
import { bigNumberify, expandDecimals, encodePriceSqrt, calcSilppage, calcPriceImpact, calcSqrtPriceLimitX96, calcFee } from "../utils/math"
import { MaxUint256, FeeAmount, TICK_SPACINGS, FeePercentageFactor} from "../utils/constants";
import { usdtDecimals, usdtOracleDecimals, uniDecimals, uniOracleDecimals, ethDecimals, ethOracleDecimals} from "../utils/constants";
import { getDexs} from "../utils/helper";
import { dexKey} from "../utils/keys";

import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'
import {
  abi as POOL_ABI,
  bytecode as POOL_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'


async function main() {
    const [owner, user0] = await ethers.getSigners();

    const roleStore = await getContract("RoleStore"); 
    const dataStore = await getContract("DataStore"); 
    const reader = await getContract("Reader");  

    //create underlyingAssets
    const usdt = await deployContract("MintableToken", ["Tether", "USDT", usdtDecimals])
    const uni = await deployContract("MintableToken", ["UNI", "UNI", uniDecimals])
    // const eth = await deployContract("MintableToken", ["ETH", "ETH", ethDecimals])
    await sendTxn(usdt.mint(owner.address, expandDecimals(200000000, usdtDecimals)), "usdt.mint");
    await sendTxn(uni.mint(owner.address, expandDecimals(20000000, uniDecimals)), "uni.mint");
    await sendTxn(usdt.mint(user0.address, expandDecimals(200000000, usdtDecimals)), "usdt.mint");
    // await sendTxn(eth.mint(owner.address, expandDecimals(10000, ethDecimals)), "eth.mint");

    //set oracle
    const usdtOracle = await deployContract("MockAggregator", [usdtOracleDecimals, expandDecimals(1, usdtOracleDecimals)]);
    const uniOracle = await deployContract("MockAggregator", [uniOracleDecimals, expandDecimals(8, uniOracleDecimals)]);
    //const ethOracle = await deployContract("MockAggregator", [ethOracleDecimals, expandDecimals(3539, ethOracleDecimals)]);
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setOracle", [usdt.target, usdtOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [usdt.target, usdtOracleDecimals]),
        config.interface.encodeFunctionData("setOracle", [uni.target, uniOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [uni.target, uniOracleDecimals]),
        // config.interface.encodeFunctionData("setOracle", [eth.target, ethOracle.target]),
        // config.interface.encodeFunctionData("setOracleDecimals", [eth.target, ethOracleDecimals]),
    ];
    await sendTxn(config.multicall(multicallArgs), "config.multicall");

    //write address
    writeTokenAddresses({"USDT": {
        "address":usdt.target, 
        "decimals":usdtDecimals, 
        "oracle":usdtOracle.target,
        "oracleDecimals":usdtOracleDecimals,
    }});

    writeTokenAddresses({"UNI": {
        "address":uni.target, 
        "decimals":uniDecimals, 
        "oracle":uniOracle.target,
        "oracleDecimals":uniOracleDecimals,
    }});

    // writeTokenAddresses({"ETH": {
    //     "address":eth.target, 
    //     "decimals":ethDecimals, 
    //     "oracle":ethOracle.target,
    //     "oracleDecimals":ethOracleDecimals,
    // }});

    console.log(readTokenAddresses());
    console.log("userUSDT", await usdt.balanceOf(owner.address)); 
    console.log("userUNI", await uni.balanceOf(owner.address)); 

    //deploy uniswapV3 and create pool
    const usdtAddress = usdt.target;
    const uniAddress = uni.target;
    const uniIsZero =  (uniAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    const factory = await deployContractWithCode(FACTORY_ABI, FACTORY_BYTECODE, owner);
    setDeployedContractAddress("UniswapV3Factory", factory.target);
    await sendTxn(await factory.createPool(usdtAddress, uniAddress, FeeAmount.MEDIUM), "factory.createPool");

    //initialize pool and mint
    const uniswapPoolAddress = await factory.getPool(uniAddress, usdtAddress,  FeeAmount.MEDIUM);
    const uniswapPool = await contractAtWithCode(POOL_ABI, POOL_BYTECODE, uniswapPoolAddress, owner);
    const sqrtPriceX96 = uniIsZero?
                         encodePriceSqrt(expandDecimals(7, usdtDecimals), expandDecimals(1, uniDecimals)):
                         encodePriceSqrt(expandDecimals(1, uniDecimals), expandDecimals(7, usdtDecimals));//1uni = 10usdt
    await sendTxn(uniswapPool.initialize(sqrtPriceX96), "uniswapPool.initialize");

    const slot0 = await uniswapPool.slot0();
    const currentTick = slot0[1];
    const uniswapV3MintCallee = await deployContract("UniswapV3MintCallee", []); 
    await sendTxn(usdt.approve(uniswapV3MintCallee.target, MaxUint256), "usdt.approve");
    await sendTxn(uni.approve(uniswapV3MintCallee.target, MaxUint256), "uni.approve");
    const tickSpacing = BigInt(TICK_SPACINGS[FeeAmount.MEDIUM]);
    const tickTrim = (currentTick / tickSpacing) * tickSpacing;
    const tickLower  = tickTrim - tickSpacing*bigNumberify(10);
    const tickUpper  = tickTrim + tickSpacing*bigNumberify(10);
    await sendTxn(uniswapV3MintCallee.mint(uniswapPool.target, owner.address, tickLower, tickUpper, expandDecimals(10, 20)), "uniswapV3MintCallee.mint");
    console.log("userUsdtAfterMint", await usdt.balanceOf(owner.address)); 
    console.log("userUniAfterMint", await uni.balanceOf(owner.address)); 

    //dex havs add role controller
    //const dex = await deployContract("DexUniswapV3", [roleStore, usdtAddress, uniAddress, FeeAmount.MEDIUM, uniswapPool.target]);
    const dex = await deployContract("DexUniswap2", [roleStore, factory.target, FeeAmount.MEDIUM]);
    // await sendTxn(uni.approve(dex.target, MaxUint256), "uni.approve");
    // await sendTxn(dex.swapExactIn(owner.address, uniAddress, expandDecimals(1, uniDecimals), owner.address, 0), "dex.swapExactIn");
    // console.log("userUsdtAfterSwap",await usdt.balanceOf(owner.address)); 
    // console.log("userUniAfterSwap",await uni.balanceOf(owner.address)); 

    //set dex
    const multicallArgs2 = [
        config.interface.encodeFunctionData("setDex", [usdt.target, uni.target, dex.target]),
    ];
    await sendTxn(config.multicall(multicallArgs2), "config.multicall");

    //quoter 
    //const feeAmount = await dex.getFeeAmount();
    const feeAmount = await reader.getDexPoolFeeAmount(dataStore, uniAddress, usdtAddress);
    const quoter = await deployContract("Quoter", [factory.target]);
    const uniAmountIn = expandDecimals(10000, uniDecimals);
    const [usdtAmountOut, startSqrtPriceX96] = await quoter.quoteExactInputSingle.staticCall(
        uniAddress, 
        usdtAddress,
        feeAmount,
        uniAmountIn,
        0 //the max sqrtPriceLimitX96 
    );
    console.log("quoter", quoter.target);
    //console.log("fee", calcFee(uniAmountIn, feeAmount, FeePercentageFactor).toString()); //should get the uni price to calc values in usd
    console.log("fee", await reader.getDexPoolSwapConstantFee(dataStore, uniAddress, usdtAddress, uniAmountIn)); 
    console.log("priceImpact", calcPriceImpact(usdtAmountOut, uniAmountIn, startSqrtPriceX96, uniIsZero).toString()); 
    console.log("silppage", calcSilppage(usdtAmountOut, uniAmountIn, startSqrtPriceX96, uniIsZero).toString()); //delete feeAmount in amountIn to get the silppage without fee
    console.log("startSqrtPriceX96", startSqrtPriceX96, "sqrtPriceLimitX96", calcSqrtPriceLimitX96(startSqrtPriceX96, "0.05", uniIsZero).toString());

    //estimateGas
    // const estimatedGas = await uni.approve.estimateGas(dex.target, MaxUint256);
    // console.log("estimatedGas", estimatedGas);

    //getDexs
    console.log("key", dexKey(usdtAddress, uniAddress));
    console.log("dexs", await getDexs(dataStore, reader)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })