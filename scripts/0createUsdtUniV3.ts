import { deployContract, deployContractWithCode, contractAtWithCode, getContract, sendTxn, writeTokenAddresses, readTokenAddresses } from "../utils/deploy"
import { bigNumberify, expandDecimals, encodePriceSqrt, calcSilppage } from "../utils/math"
import { MaxUint256, FeeAmount, TICK_SPACINGS} from "../utils/constants";
import { usdtDecimals, usdtOracleDecimal, uniDecimals, uniOracleDecimal} from "../utils/constants";

import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'
import {
  abi as POOL_ABI,
  bytecode as POOL_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'


async function main() {
    const [owner] = await ethers.getSigners();

    //create underlyingAssets
    const usdt = await deployContract("MintableToken", ["Tether", "USDT", usdtDecimals])
    const uni = await deployContract("MintableToken", ["UNI", "UNI", uniDecimals])
    await sendTxn(usdt.mint(owner.address, expandDecimals(100000000, usdtDecimals)), "usdt.mint");
    await sendTxn(uni.mint(owner.address, expandDecimals(20000000, uniDecimals)), "uni.mint");

    //set oracle
    const usdtOracle = await deployContract("MockAggregator", [usdtOracleDecimal, expandDecimals(1, usdtOracleDecimal)]);
    const uniOracle = await deployContract("MockAggregator", [uniOracleDecimal, expandDecimals(10, uniOracleDecimal)]);
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setOracle", [usdt.target, usdtOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [usdt.target, usdtOracleDecimal]),
        config.interface.encodeFunctionData("setOracle", [uni.target, uniOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [uni.target, uniOracleDecimal]),
    ];
    await sendTxn(config.multicall(multicallArgs), "config.multicall");

    //write address
    writeTokenAddresses({"USDT": {
        "address":usdt.target, 
        "decimals":usdtDecimals, 
        "oracle":usdtOracle.target,
        "oracleDecimals":usdtOracleDecimal,
    }});

    writeTokenAddresses({"UNI": {
        "address":uni.target, 
        "decimals":uniDecimals, 
        "oracle":uniOracle.target,
        "oracleDecimals":uniOracleDecimal,
    }});

    console.log(readTokenAddresses());
    console.log("userUSDT", await usdt.balanceOf(owner.address)); 
    console.log("userUNI", await uni.balanceOf(owner.address)); 

    //deploy uniswapV3 and create pool
    const usdtAddress = usdt.target;
    const uniAddress = uni.target;
    const uniIsZero =  (uniAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    const factory = await deployContractWithCode(FACTORY_ABI, FACTORY_BYTECODE, owner);
    await sendTxn(await factory.createPool(usdtAddress, uniAddress, FeeAmount.MEDIUM), "factory.createPool");

    //initialize pool and mint
    const uniswapPoolAddress = await factory.getPool(uniAddress, usdtAddress,  FeeAmount.MEDIUM);
    const uniswapPool = await contractAtWithCode(POOL_ABI, POOL_BYTECODE, uniswapPoolAddress, owner);
    const sqrtPriceX96 = uniIsZero?
                         encodePriceSqrt(expandDecimals(10, usdtDecimals), expandDecimals(1, uniDecimals)):
                         encodePriceSqrt(expandDecimals(1, uniDecimals), expandDecimals(10, usdtDecimals));//1uni = 10usdt
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

    //swap 
    const quoter = await deployContract("Quoter", [factory.target]);
    const uniAmountIn = expandDecimals(10000, uniDecimals);
    const [usdtAmountOut, startSqrtPriceX96] = await quoter.quoteExactInputSingle.staticCall(
        uniAddress, 
        usdtAddress,
        FeeAmount.MEDIUM,
        uniAmountIn,
        0 //the max sqrtPriceLimitX96 
    );
    console.log("silppage", calcSilppage(usdtAmountOut, uniAmountIn, startSqrtPriceX96, uniIsZero).toString()); 

    //swap 
    const dex = await deployContract("DexUniswapV3", [usdtAddress, uniAddress, FeeAmount.MEDIUM, uniswapPool.target]);
    await sendTxn(uni.approve(dex.target, MaxUint256), "uni.approve");
    await sendTxn(dex.swapExactIn(owner.address, uniAddress, expandDecimals(1, uniDecimals), owner.address), "dex.swapExactIn");
    console.log("userUsdtAfterSwap",await usdt.balanceOf(owner.address)); 
    console.log("userUniAfterSwap",await uni.balanceOf(owner.address)); 

    //set dex
    const multicallArgs2 = [
        config.interface.encodeFunctionData("setDex", [usdt.target, uni.target, dex.target]),
    ];
    await sendTxn(config.multicall(multicallArgs2), "config.multicall");
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })