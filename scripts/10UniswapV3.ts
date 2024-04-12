import { contractAt, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt, getWebSocketContract } from "../utils/deploy";
import { expandDecimals, encodePriceSqrt, decodePriceSqrt } from "../utils/math";
import { getPoolInfo, getLiquidity, getDebt} from "../utils/helper";
import { FeeAmount} from "../utils/constants";
import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'

import {
  abi as POOL_ABI,
  bytecode as POOL_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'


const { mine } = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    const [owner] = await ethers.getSigners();

    const usdtDecimals = 6;
    const uniDecimals = 18;
    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];

    const contractFactory = new ethers.ContractFactory(FACTORY_ABI, FACTORY_BYTECODE, owner);
    const factory = await contractFactory.deploy();
    await factory.createPool(usdtAddress, uniAddress, FeeAmount.MEDIUM);

    const poolAddress = await factory.getPool(uniAddress, usdtAddress,  FeeAmount.MEDIUM);
    const contractFactoryPool = new ethers.ContractFactory(POOL_ABI, POOL_BYTECODE, owner);
    const pool = await contractFactoryPool.attach(poolAddress);

    const sqrtPriceX96 = encodePriceSqrt(expandDecimals(1000, uniDecimals), expandDecimals(10000, usdtDecimals));
    const price = decodePriceSqrt(sqrtPriceX96);
    console.log(sqrtPriceX96, price);

    const poolWebSocket = await getWebSocketContract(POOL_ABI, POOL_BYTECODE, poolAddress);
    poolWebSocket.on("Initialize", (sqrtPriceX96, tick) =>{
        console.log("Initialize" , sqrtPriceX96, tick);
    });
    await pool.initialize(sqrtPriceX96);

    console.log("factory", await pool.factory());
    console.log("token0", await pool.token0());
    console.log("token1", await pool.token1());
    console.log("fee", await pool.fee());
    console.log("tickSpacing", await pool.tickSpacing());

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })