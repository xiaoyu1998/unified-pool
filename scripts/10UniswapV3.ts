import { contractAt, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt, getWebSocketContract } from "../utils/deploy";
import { bigNumberify, expandDecimals, encodePriceSqrt, decodePriceSqrt } from "../utils/math";
import { getPoolInfo, getLiquidity, getDebt} from "../utils/helper";
import { MaxUint256, FeeAmount, TICK_SPACINGS} from "../utils/constants";
import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'

import {
  abi as POOL_ABI,
  bytecode as POOL_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'

// import {
//   abi as FACTORY_ABI,
//   bytecode as FACTORY_BYTECODE,
// } from '/Users/xiaoyu/work/uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'

// import {
//   abi as POOL_ABI,
//   bytecode as POOL_BYTECODE,
// } from '/Users/xiaoyu/work/uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'


const { mine } = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    const [owner] = await ethers.getSigners();

    const usdtDecimals = 6;
    const uniDecimals = 18;
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uni = await contractAt("MintableToken", uniAddress);
    console.log("userUSDT",await usdt.balanceOf(owner.address)); 
    console.log("userUni",await uni.balanceOf(owner.address));
    const uniIsZero =  (uniAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    console.log("uniIsZero", uniIsZero);

    //create pool
    const contractFactory = new ethers.ContractFactory(FACTORY_ABI, FACTORY_BYTECODE, owner);
    const factory = await contractFactory.deploy();
    await factory.createPool(usdtAddress, uniAddress, FeeAmount.MEDIUM);
    const poolAddress = await factory.getPool(uniAddress, usdtAddress,  FeeAmount.MEDIUM);
    const contractFactoryPool = new ethers.ContractFactory(POOL_ABI, POOL_BYTECODE, owner);
    const pool = await contractFactoryPool.attach(poolAddress);

    //initialize pool
    const poolWebSocket = await getWebSocketContract(undefined, POOL_ABI, POOL_BYTECODE, poolAddress);
    poolWebSocket.on("Initialize", (sqrtPriceX96, tick) =>{
        console.log("Initialize" , sqrtPriceX96, tick);
    });
    const sqrtPriceX96 = uniIsZero?
                         encodePriceSqrt(expandDecimals(10, usdtDecimals), expandDecimals(1, uniDecimals)):
                         encodePriceSqrt(expandDecimals(1, uniDecimals), expandDecimals(10, usdtDecimals));
    //console.log("sqrtPriceX96", sqrtPriceX96);
    await pool.initialize(sqrtPriceX96);

    const slot0 = await pool.slot0();
    const currentTick = slot0[1];
    console.log("currentTick", currentTick, sqrtPriceX96);

    //provide liquidity
    const uniswapV3CalleeWebSocket = await getWebSocketContract("UniswapV3Callee");
    uniswapV3CalleeWebSocket.on("MintCallback", (amount0Owed, amount1Owed) =>{
        console.log("MintCallback" , amount0Owed, amount1Owed);
    });
    const uniswapV3Callee = await getContract("UniswapV3Callee");
    await sendTxn(usdt.approve(uniswapV3Callee.target, MaxUint256), `usdt.approve(${uniswapV3Callee.target})`)  
    await sendTxn(uni.approve(uniswapV3Callee.target, MaxUint256), `uni.approve(${uniswapV3Callee.target})`)  
    const tickSpacing = BigInt(TICK_SPACINGS[FeeAmount.MEDIUM]);
    const tickTrim = (currentTick / tickSpacing) * tickSpacing;
    const tickLower  = tickTrim - tickSpacing*bigNumberify(10);
    const tickUpper  = tickTrim + tickSpacing;
    console.log(tickTrim, tickLower, tickUpper);
    await uniswapV3Callee.mint(pool.target, owner.address, tickLower, tickUpper, expandDecimals(1, 16));
    console.log("userUsdtAfterMint",await usdt.balanceOf(owner.address)); 
    console.log("userUniAfterMint",await uni.balanceOf(owner.address)); 

    //swap
    const sqrtPriceLimitX96 = uniIsZero?
                         encodePriceSqrt(expandDecimals(8, usdtDecimals), expandDecimals(1, uniDecimals)):
                         encodePriceSqrt(expandDecimals(1, uniDecimals), expandDecimals(8, usdtDecimals));
    const swap = uniIsZero?uniswapV3Callee.swapExact0For1:uniswapV3Callee.swap1ForExact0;
    await swap(pool.target, expandDecimals(1, uniDecimals), owner.address, sqrtPriceLimitX96);
    console.log("userUsdtAfterSwap",await usdt.balanceOf(owner.address)); 
    console.log("userUniAfterSwap",await uni.balanceOf(owner.address)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })