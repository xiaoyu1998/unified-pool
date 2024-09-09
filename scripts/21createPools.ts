import { getContract, sendTxn, getTokens } from "../utils/deploy";
import { bigNumberify, expandDecimals } from "../utils/math";
import { parsePool } from "../utils/helper";
import { CreatePoolParamsStructOutput } from "../typechain-types/contracts/pool/PoolFactory";

async function main() {
    const [owner] = await ethers.getSigners();

    const dataStore = await getContract("DataStore");    
    const reader = await getContract("Reader");   

    //create pools
    const usdt = getTokens("USDT")["address"];
    const uni  = getTokens("UNI")["address"];
    const usdtDecimals = getTokens("USDT")["decimals"];
    const uniDecimals = getTokens("UNI")["decimals"];
    const poolFactory = await getContract("PoolFactory");
    const poolInterestRateStrategy = await getContract("PoolInterestRateStrategy");

    //create usdt and eth pool
    await sendTxn(
        poolFactory.createPool(usdt, poolInterestRateStrategy.target, configuration),
        "poolFactory.createPool(usdt)"
    );

    await sendTxn(
        poolFactory.createPool(eth, poolInterestRateStrategy.target, configuration),
        "poolFactory.createPool(eth)"
    );

    //set pools configuration
    const config = await getContract("Config");
    const dex = await reader.getDex(dataStore.target, usdt.target, uni.target);

    const multicallArgs = [
        config.interface.encodeFunctionData("setTreasury", [owner.address]),
        config.interface.encodeFunctionData("setHealthFactorLiquidationThreshold", [expandDecimals(110, 25)]),//110%
        config.interface.encodeFunctionData("setDebtMultiplierFactorForRedeem", [expandDecimals(2, 27)]),//2x
        //User Pool Settings
        config.interface.encodeFunctionData("setUserPoolInterestRateStrategy", poolInterestRateStrategy.target),
        config.interface.encodeFunctionData("setUserPoolUnderlyingAssetUsd", usdt),
        config.interface.encodeFunctionData("setUserPoolConfiguration", bigNumberify(0x3e80500000000000000)),//feeFactor 10%
        config.interface.encodeFunctionData("setUserPoolDex", dex),
        config.interface.encodeFunctionData("setUserPoolOracleDecimals", 12),
        config.interface.encodeFunctionData("setCreateUserPoolOpen", true),
    ];
    await sendTxn(
        config.multicall(multicallArgs),
        "config.multicall"
    );

    // usdt and uni pool settings
    const multicallArgs2 = [
        //usdt
        config.interface.encodeFunctionData("setPoolActive", [usdt, true]),
        config.interface.encodeFunctionData("setPoolFrozen", [usdt, false]),
        config.interface.encodeFunctionData("setPoolPaused", [usdt, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [usdt, true]),
        config.interface.encodeFunctionData("setPoolDecimals", [usdt, usdtDecimals]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [usdt, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [usdt, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [usdt, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolUsd", [usdt, true]),
        //uni
        config.interface.encodeFunctionData("setPoolActive", [uni, true]),
        config.interface.encodeFunctionData("setPoolFrozen", [uni, false]),
        config.interface.encodeFunctionData("setPoolPaused", [uni, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [uni, true]),
        config.interface.encodeFunctionData("setPoolDecimals", [uni, uniDecimals]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [uni, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [uni, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [uni, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolUsd", [uni, false]),
    ];
    await sendTxn(
        config.multicall(multicallArgs2),
        "config.multicall"
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