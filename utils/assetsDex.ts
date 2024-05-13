
import { sendTxn, deployContract, deployContractWithCode, contractAtWithCode } from "./deploy";
import { expandDecimals, encodePriceSqrt } from "./math"
import { FeeAmount } from "./constants";
import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'
import {
  abi as POOL_ABI,
  bytecode as POOL_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'

export async function createAsset(account, config, name, symbol, amount, decimals, oracleDecimal, price) {

    //create underlyingAssets
    const token = await deployContract("MintableToken", [name, symbol, decimals])
    await sendTxn(token.mint(account.address, expandDecimals(amount, decimals)), "token.mint");

    //set oracle
    const oracle = await deployContract("MockAggregator", [oracleDecimal, expandDecimals(price, oracleDecimal)]);
    const multicallArgs = [
        config.interface.encodeFunctionData("setOracle", [token.target, oracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [token.target, oracleDecimal]),
    ];
    await sendTxn(config.multicall(multicallArgs), "config.multicall");

    return token;
}

export async function createUniswapV3(account, config, token0, token0Decimals, token1, token1Decimals, price) {
    //deploy uniswapV3 and create pool
    const token0Address = token0.target;
    const token1Address = token1.target;
    const token1IsZero =  (token1Address.toLowerCase() < token0Address.toLowerCase()) ? true:false;
    const factory = await deployContractWithCode(FACTORY_ABI, FACTORY_BYTECODE, account);
    await sendTxn(await factory.createPool(token0Address, token1Address, FeeAmount.MEDIUM), "factory.createPool");

    //initialize pool and mint
    const poolAddress = await factory.getPool(token1Address, token0Address, FeeAmount.MEDIUM);
    const pool = await contractAtWithCode(POOL_ABI, POOL_BYTECODE, poolAddress, account);
    const sqrtPriceX96 = token1IsZero?
                         encodePriceSqrt(expandDecimals(price, token0Decimals), expandDecimals(1, token1Decimals)):
                         encodePriceSqrt(expandDecimals(1, token1Decimals), expandDecimals(price, token0Decimals));//1token1 = 10token0
    await sendTxn(pool.initialize(sqrtPriceX96), "pool.initialize");

    const dex = await deployContract("DexUniswapV3", [token0Address, token1Address, FeeAmount.MEDIUM, pool.target]);

    //set dex
    const multicallArgs2 = [
        config.interface.encodeFunctionData("setDex", [token0.target, token1.target, dex.target]),
    ];
    await sendTxn(config.multicall(multicallArgs2), "config.multicall");

    return dex;
}