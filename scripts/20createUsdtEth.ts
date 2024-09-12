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

    //create usdt and eth
    const usdt = await deployContract("MintableToken", ["Tether", "USDT", usdtDecimals])
    const eth = await deployContract("MintableToken", ["ETH", "ETH", ethDecimals])
    await sendTxn(usdt.mint(owner.address, expandDecimals(200000000, usdtDecimals)), "usdt.mint");
    await sendTxn(usdt.mint(user0.address, expandDecimals(200000000, usdtDecimals)), "usdt.mint");
    await sendTxn(eth.mint(owner.address, expandDecimals(2000000, ethDecimals)), "eth.mint");

    //set oracle
    const usdtOracle = await deployContract("MockAggregator", [usdtOracleDecimals, expandDecimals(1, usdtOracleDecimals)]);
    const ethOracle = await deployContract("MockAggregator", [ethOracleDecimals, expandDecimals(3539, ethOracleDecimals)]);
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setOracle", [usdt.target, usdtOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [usdt.target, usdtOracleDecimals]),
        config.interface.encodeFunctionData("setOracle", [eth.target, ethOracle.target]),
        config.interface.encodeFunctionData("setOracleDecimals", [eth.target, ethOracleDecimals]),
    ];
    await sendTxn(config.multicall(multicallArgs), "config.multicall");

    //write address
    writeTokenAddresses({"USDT": {
        "address":usdt.target, 
        "decimals":usdtDecimals, 
        "oracle":usdtOracle.target,
        "oracleDecimals":usdtOracleDecimals,
    }});

    writeTokenAddresses({"ETH": {
        "address":eth.target, 
        "decimals":ethDecimals, 
        "oracle":ethOracle.target,
        "oracleDecimals":ethOracleDecimals,
    }});

    console.log(readTokenAddresses());
    console.log("userUsdtAfterMint", await usdt.balanceOf(owner.address)); 
    console.log("userEthAfterMint", await eth.balanceOf(owner.address)); 

    //deploy uniswapV3 and create pool
    const usdtAddress = usdt.target;
    const ethAddress = eth.target;
    const ethIsZero =  (ethAddress.toLowerCase() < usdtAddress.toLowerCase()) ? true:false;
    const factory = await deployContractWithCode(FACTORY_ABI, FACTORY_BYTECODE, owner);
    setDeployedContractAddress("UniswapV3Factory", factory.target);
    await sendTxn(await factory.createPool(usdtAddress, ethAddress, FeeAmount.MEDIUM), "factory.createPool");

    //initialize swap pool and mint
    const uniswapPoolAddress = await factory.getPool(ethAddress, usdtAddress,  FeeAmount.MEDIUM);
    const uniswapPool = await contractAtWithCode(POOL_ABI, POOL_BYTECODE, uniswapPoolAddress, owner);
    const sqrtPriceX96 = ethIsZero?
                         encodePriceSqrt(expandDecimals(3000, usdtDecimals), expandDecimals(1, ethDecimals)):
                         encodePriceSqrt(expandDecimals(1, ethDecimals), expandDecimals(3000, usdtDecimals));//1uni = 10usdt
    await sendTxn(uniswapPool.initialize(sqrtPriceX96), "uniswapPool.initialize");

    const slot0 = await uniswapPool.slot0();
    const currentTick = slot0[1];
    const uniswapV3MintCallee = await deployContract("UniswapV3MintCallee", []); 
    await sendTxn(usdt.approve(uniswapV3MintCallee.target, MaxUint256), "usdt.approve");
    await sendTxn(eth.approve(uniswapV3MintCallee.target, MaxUint256), "eth.approve");
    const tickSpacing = BigInt(TICK_SPACINGS[FeeAmount.MEDIUM]);
    const tickTrim = (currentTick / tickSpacing) * tickSpacing;
    const tickLower  = tickTrim - tickSpacing*bigNumberify(10);
    const tickUpper  = tickTrim + tickSpacing*bigNumberify(10);
    await sendTxn(uniswapV3MintCallee.mint(uniswapPool.target, owner.address, tickLower, tickUpper, expandDecimals(1, 20)), "uniswapV3MintCallee.mint");
    console.log("userUsdtAfterMint", await usdt.balanceOf(owner.address)); 
    console.log("userEthAfterMint", await eth.balanceOf(owner.address)); 

    //set dex
    const dex = await deployContract("DexUniswap2", [roleStore, factory.target, FeeAmount.MEDIUM]);
    const multicallArgs2 = [
        config.interface.encodeFunctionData("setDex", [usdt.target, eth.target, dex.target]),
    ];
    await sendTxn(config.multicall(multicallArgs2), "config.multicall");

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