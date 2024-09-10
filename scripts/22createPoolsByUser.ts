import { deployContract,  contractAtWithCode, contractAt, getDeployedContractAddress, getContract, sendTxn, getTokens, writeTokenAddresses } from "../utils/deploy"
import { bigNumberify, expandDecimals,encodePriceSqrt } from "../utils/math"
import { MaxUint256, FeeAmount, TICK_SPACINGS } from "../utils/constants";
import { tokenDecimals} from "../utils/constants";
import { parsePool} from "../utils/helper";

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

    //const roleStore = await getContract("RoleStore"); 
    const dataStore = await getContract("DataStore"); 
    const reader = await getContract("Reader");  
    const poolFactory = await getContract("PoolFactory");  

    //create Eth token
    const eth = await deployContract("MintableToken", ["ETH", "ETH", tokenDecimals], user0)
    await sendTxn(eth.connect(user0).mint(user0.address, expandDecimals(1000000, tokenDecimals)), "eth.mint");

    let tokenOracleDecimals = await reader.getUserPoolOracleDecimals(dataStore.target);
    writeTokenAddresses({"ETH": {
        "address": eth.target, 
        "decimals": tokenDecimals, 
        "oracle": ethers.ZeroAddress,//user created pool
        "oracleDecimals": tokenOracleDecimals.toString(),
    }});

    console.log("ethOracleDecimals", tokenOracleDecimals.toString())

    //create swap pool
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const ethAddress = eth.target;
    const ethIsZero =  (ethAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    const factoryAddress = getDeployedContractAddress("UniswapV3Factory"); 
    const factory = await contractAtWithCode(FACTORY_ABI, FACTORY_BYTECODE, factoryAddress, user0)
    //console.log(factoryAddress, factory);
    await sendTxn(await factory.connect(user0).createPool(usdtAddress, ethAddress, FeeAmount.MEDIUM), "factory.createPool");

    const userUsdtBeforeMint = await usdt.balanceOf(user0.address);
    const userEthBeforeMint = await eth.balanceOf(user0.address);
    console.log("userUsdtBeforeMint", userUsdtBeforeMint); 
    console.log("userEthBeforeMint", userEthBeforeMint); 

    //initialize pool and mint
    const uniswapPoolAddress = await factory.getPool(usdtAddress, ethAddress,  FeeAmount.MEDIUM);
    const uniswapPool = await contractAtWithCode(POOL_ABI, POOL_BYTECODE, uniswapPoolAddress, user0);
    const sqrtPriceX96 = ethIsZero?
                         encodePriceSqrt(expandDecimals(3000, usdtDecimals), expandDecimals(1, tokenDecimals)):
                         encodePriceSqrt(expandDecimals(1, tokenDecimals), expandDecimals(3000, usdtDecimals));
    await sendTxn(uniswapPool.connect(user0).initialize(sqrtPriceX96), "uniswapPool.initialize");

    const slot0 = await uniswapPool.slot0();
    const currentTick = slot0[1];
    const uniswapV3MintCallee = await deployContract("UniswapV3MintCallee", []); 
    await sendTxn(usdt.connect(user0).approve(uniswapV3MintCallee.target, MaxUint256), "usdt.approve");
    await sendTxn(eth.connect(user0).approve(uniswapV3MintCallee.target, MaxUint256), "eth.approve");
    const tickSpacing = BigInt(TICK_SPACINGS[FeeAmount.MEDIUM]);
    const tickTrim = (currentTick / tickSpacing) * tickSpacing;
    const tickLower  = tickTrim - tickSpacing*bigNumberify(10);
    const tickUpper  = tickTrim + tickSpacing*bigNumberify(10);
    await sendTxn(uniswapV3MintCallee.connect(user0).mint(uniswapPool.target, user0.address, tickLower, tickUpper, expandDecimals(1, 20)), "uniswapV3MintCallee.mint");
    console.log("userUsdtAfterMint", await usdt.balanceOf(user0.address)); 
    console.log("userEthAfterMint", await eth.balanceOf(user0.address)); 

    // create eth pool
    const paramsEth: CreatePoolParamsStructOutput = {
        underlyingAsset: eth.target,
        borrowCapacity: expandDecimals(1, 8),
        supplyCapacity: expandDecimals(1, 8),
    };    
    await sendTxn(
        poolFactory.createPoolByUser(paramsEth),
        "poolFactory.createPoolByUser(Eth)"
    );

    //print pools
    const pools = await reader.getPools(dataStore.target);
    for (const pool of pools) {
        console.log(parsePool(pool));
    }

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })