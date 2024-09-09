import { deployContract, deployContractWithCode, contractAtWithCode, getContract, sendTxn, writeTokenAddresses, readTokenAddresses, setDeployedContractAddress } from "../utils/deploy"
import { bigNumberify, expandDecimals, encodePriceSqrt, calcSilppage, calcPriceImpact, calcSqrtPriceLimitX96, calcFee } from "../utils/math"
import { MaxUint256, FeeAmount, TICK_SPACINGS, FeePercentageFactor} from "../utils/constants";
import { usdtDecimals, usdtOracleDecimals, uniDecimals, uniOracleDecimals, tokenDecimals} from "../utils/constants";
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

    //create Eth token
    const eth = await deployContract("MintableToken", ["ETH", "ETH", tokenDecimals], user0)
    await sendTxn(eth.connect(user0).mint(owner.address, expandDecimals(1000000, tokenDecimals)), "eth.mint");

    let tokenOracleDecimals = await reader.getUserPoolOracleDecimals(dataStore.target);
    writeTokenAddresses({"ETH": {
        "address":eth.target, 
        "decimals":tokenDecimals, 
        "oracle":ethOracle.target,
        "oracleDecimals":tokenOracleDecimals,
    }});

    //create swap pool
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    const ethAddress = eth.target;
    const ethIsZero =  (ethAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    const factoryAddress = getDeployedContractAddress("UniswapV3Factory"); 
    const factory = contractAtWithCode(FACTORY_ABI, FACTORY_BYTECODE, factoryAddress)
    await sendTxn(await factory.connect(user0).createPool(usdtAddress, ethAddress, FeeAmount.MEDIUM), "factory.createPool");

    //initialize pool and mint
    const uniswapPoolAddress = await factory.getPool(ethAddress, usdtAddress, FeeAmount.MEDIUM);
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
    await sendTxn(uniswapV3MintCallee.connect(user0).mint(uniswapPool.target, user0.address, tickLower, tickUpper, expandDecimals(10, 10)), "uniswapV3MintCallee.mint");
    console.log("userUsdtAfterMint", await usdt.balanceOf(user0.address)); 
    console.log("userUniAfterMint", await eth.balanceOf(user0.address)); 

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

    //getDexs
    console.log("key", dexKey(usdtAddress, ethAddress));
    console.log("dexs", await getDexs(dataStore, reader)); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })