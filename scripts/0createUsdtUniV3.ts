import { deployContract, sendTxn, writeTokenAddresses, readTokenAddresses, getTokens, getContract } from "../utils/deploy"
import { bigNumberify, expandDecimals, encodePriceSqrt } from "../utils/math"
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

    //create underlyingAsset
    const usdt = await deployContract("MintableToken", ["Tether", "USDT", usdtDecimals])
    const uni = await deployContract("MintableToken", ["UNI", "UNI", uniDecimals])
    await sendTxn(usdt.mint(owner.address, expandDecimals(1000000, usdtDecimals)), `usdt.mint(${owner.address})`)
    await sendTxn(uni.mint(owner.address, expandDecimals(10000, uniDecimals)), `usdt.mint(${owner.address})`)

    //set oracle
    const usdtOracle = await deployContract("MockPriceFeed", []);
    const uniOracle = await deployContract("MockPriceFeed", []);
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setOracle", [usdt.target, usdtOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [usdt.target, usdtOracleDecimal]),
        config.interface.encodeFunctionData("setOracle", [uni.target, uniOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [uni.target, uniOracleDecimal]),
    ];
    const tx = await config.multicall(multicallArgs);

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

    // console.log(getTokens("usdt")["priceFeed"]);
    console.log(readTokenAddresses());
    console.log("userUSDT", await usdt.balanceOf(owner.address)); 
    console.log("userUNI", await uni.balanceOf(owner.address)); 

    //deploy uniswapV3 and create pool
    const usdtAddress = usdt.target;
    const uniAddress = uni.target;
    const uniIsZero =  (uniAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    const contractFactory = new ethers.ContractFactory(FACTORY_ABI, FACTORY_BYTECODE, owner);
    const factory = await contractFactory.deploy();
    await factory.createPool(usdtAddress, uniAddress, FeeAmount.MEDIUM);
    const uniswapPoolAddress = await factory.getPool(uniAddress, usdtAddress,  FeeAmount.MEDIUM);
    const contractFactoryPool = new ethers.ContractFactory(POOL_ABI, POOL_BYTECODE, owner);
    const uniswapPool = await contractFactoryPool.attach(uniswapPoolAddress);

    //initialize and mint
    //initialize pool
    // const poolWebSocket = await getWebSocketContract(undefined, POOL_ABI, POOL_BYTECODE, uniswapPoolAddress);
    // poolWebSocket.on("Initialize", (sqrtPriceX96, tick) =>{
    //     console.log("Initialize" , sqrtPriceX96, tick);
    // });
    const sqrtPriceX96 = uniIsZero?
                         encodePriceSqrt(expandDecimals(10, usdtDecimals), expandDecimals(1, uniDecimals)):
                         encodePriceSqrt(expandDecimals(1, uniDecimals), expandDecimals(10, usdtDecimals));
    await uniswapPool.initialize(sqrtPriceX96);
    const slot0 = await uniswapPool.slot0();
    const currentTick = slot0[1];
    const uniswapV3MintCallee = await deployContract("UniswapV3MintCallee", []);
    await sendTxn(usdt.approve(uniswapV3MintCallee.target, MaxUint256), `usdt.approve(${uniswapV3MintCallee.target})`)  
    await sendTxn(uni.approve(uniswapV3MintCallee.target, MaxUint256), `uni.approve(${uniswapV3MintCallee.target})`)  
    const tickSpacing = BigInt(TICK_SPACINGS[FeeAmount.MEDIUM]);
    const tickTrim = (currentTick / tickSpacing) * tickSpacing;
    const tickLower  = tickTrim - tickSpacing*bigNumberify(10);
    const tickUpper  = tickTrim + tickSpacing;
    console.log(tickTrim, tickLower, tickUpper);
    await uniswapV3MintCallee.mint(uniswapPool.target, owner.address, tickLower, tickUpper, expandDecimals(1, 16));
    console.log("userUsdtAfterMint",await usdt.balanceOf(owner.address)); 
    console.log("userUniAfterMint",await uni.balanceOf(owner.address)); 

    //swap 
    const dex = await deployContract("DexUniswapV3", [usdtAddress, uniAddress, FeeAmount.MEDIUM, uniswapPool.target]);
    const sqrtPriceLimitX96 = uniIsZero?
                       encodePriceSqrt(expandDecimals(8, usdtDecimals), expandDecimals(1, uniDecimals)):
                       encodePriceSqrt(expandDecimals(1, uniDecimals), expandDecimals(8, usdtDecimals));
    await sendTxn(uni.approve(dex.target, MaxUint256), `uni.approve(${dex.target})`) 
    await dex.swap(owner.address, uniAddress, expandDecimals(1, uniDecimals), owner.address, sqrtPriceLimitX96);
    console.log("userUsdtAfterSwap",await usdt.balanceOf(owner.address)); 
    console.log("userUniAfterSwap",await uni.balanceOf(owner.address)); 

    //set dex
    const multicallArgs2 = [
        config.interface.encodeFunctionData("setDex", [usdt.target, uni.target, dex.target]),
    ];
    const tx2 = await config.multicall(multicallArgs2);   

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })