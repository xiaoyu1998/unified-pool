import { getContract, sendTxn, getTokens } from "../utils/deploy";
import { bigNumberify, expandDecimals } from "../utils/math";
import { getPool } from "../utils/helper";

async function main() {
    const [owner] = await ethers.getSigners();
    //create pools
    const uni = getTokens("USDT")["address"];
    const configuration = 0;//TODO:should be assgined to a reasonable configuration
    const poolFactory = await getContract("PoolFactory");
    const poolInterestRateStrategy = await getContract("PoolInterestRateStrategy");

    await sendTxn(
        poolFactory.createPool(uni, poolInterestRateStrategy.target, configuration),
        "poolFactory.createPool(uni)"
    );

    //set pools configuration
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setPoolActive", [uni, true]),
        config.interface.encodeFunctionData("setPoolFrozen", [uni, false]),
        config.interface.encodeFunctionData("setPoolPaused", [uni, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [uni, true]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [uni, 1000]), //10%
        config.interface.encodeFunctionData("setPoolUsd", [uni, false]),
    ];
    await sendTxn(
        config.multicall(multicallArgs),
        "config.multicall"
    );

    //print pool 
    const pool= await getPool(uni);
    //console.log('0x' + pool.configuration.toString(16));
    console.log(pool.configuration);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })