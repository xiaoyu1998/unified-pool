import { deployContract,  contractAtWithCode, contractAt, getDeployedContractAddress, getContract, sendTxn, getTokens, writeTokenAddresses } from "../utils/deploy"
import { bigNumberify, expandDecimals,encodePriceSqrt } from "../utils/math"
import { MaxUint256, FeeAmount, TICK_SPACINGS } from "../utils/constants";
import { tokenDecimals} from "../utils/constants";
import { parsePool, parseToken} from "../utils/helper";

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

    //create Uni token
    const uni = await deployContract("MintableToken", ["UNI", "UNI", tokenDecimals], user0)
    await sendTxn(uni.connect(user0).mint(user0.address, expandDecimals(2000000, tokenDecimals)), "uni.mint");
    await sendTxn(uni.connect(user0).mint(owner.address, expandDecimals(2000000, tokenDecimals)), "uni.mint");

    //let tokenOracleDecimals = await reader.getUserPoolOracleDecimals(dataStore.target);
    let tokenOracleDecimals = await poolFactory.oracleDecimals();
    writeTokenAddresses({"UNI": {
        "address": uni.target, 
        "decimals": tokenDecimals, 
        "oracle": ethers.ZeroAddress,//user created pool
        "oracleDecimals": Number(tokenOracleDecimals),
    }});

    console.log("uniOracleDecimals", tokenOracleDecimals.toString())

    //create swap pool
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const uniAddress = uni.target;
    const uniIsZero =  (uniAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    const factoryAddress = getDeployedContractAddress("UniswapV3Factory"); 
    const factory = await contractAtWithCode(FACTORY_ABI, FACTORY_BYTECODE, factoryAddress, user0)
    //console.log(factoryAddress, factory);
    await sendTxn(await factory.connect(user0).createPool(usdtAddress, uniAddress, FeeAmount.MEDIUM), "factory.createPool");

    const userUsdtBeforeMint = await usdt.balanceOf(user0.address);
    const userUniBeforeMint = await uni.balanceOf(user0.address);
    console.log("userUsdtBeforeMint", userUsdtBeforeMint); 
    console.log("userUniBeforeMint", userUniBeforeMint); 

    //initialize pool and mint
    const uniswapPoolAddress = await factory.getPool(usdtAddress, uniAddress,  FeeAmount.MEDIUM);
    const uniswapPool = await contractAtWithCode(POOL_ABI, POOL_BYTECODE, uniswapPoolAddress, user0);
    const sqrtPriceX96 = uniIsZero?
                         encodePriceSqrt(expandDecimals(7, usdtDecimals), expandDecimals(1, tokenDecimals)):
                         encodePriceSqrt(expandDecimals(1, tokenDecimals), expandDecimals(7, usdtDecimals));
    await sendTxn(uniswapPool.connect(user0).initialize(sqrtPriceX96), "uniswapPool.initialize");

    const slot0 = await uniswapPool.slot0();
    const currentTick = slot0[1];
    const uniswapV3MintCallee = await deployContract("UniswapV3MintCallee", []); 
    await sendTxn(usdt.connect(user0).approve(uniswapV3MintCallee.target, MaxUint256), "usdt.approve");
    await sendTxn(uni.connect(user0).approve(uniswapV3MintCallee.target, MaxUint256), "uni.approve");
    const tickSpacing = BigInt(TICK_SPACINGS[FeeAmount.MEDIUM]);
    const tickTrim = (currentTick / tickSpacing) * tickSpacing;
    const tickLower  = tickTrim - tickSpacing*bigNumberify(10);
    const tickUpper  = tickTrim + tickSpacing*bigNumberify(10);
    await sendTxn(uniswapV3MintCallee.connect(user0).mint(uniswapPool.target, user0.address, tickLower, tickUpper, expandDecimals(1, 20)), "uniswapV3MintCallee.mint");
    console.log("userUsdtAfterMint", await usdt.balanceOf(user0.address)); 
    console.log("userUniAfterMint", await uni.balanceOf(user0.address)); 

    // create uni pool
    const paramsUni: CreatePoolParamsStructOutput = {
        underlyingAsset: uni.target,
        borrowCapacity: expandDecimals(1, 8),
        supplyCapacity: expandDecimals(1, 8),
    };    
    await sendTxn(
        poolFactory.createPoolByUser(paramsUni),
        "poolFactory.createPoolByUser(Uni)"
    );

    //print pools
    const pools = await reader.getPools(dataStore.target);
    for (const pool of pools) {
        console.log(parsePool(pool));
    }

    const tokens = await reader.getTokens(dataStore.target);
    for (const token of tokens) {
        console.log(parseToken(token));
    }    

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })