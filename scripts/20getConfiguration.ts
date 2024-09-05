import { getContract, sendTxn, getTokens } from "../utils/deploy";
import { bigNumberify, expandDecimals } from "../utils/math";
import { getPool } from "../utils/helper";

async function main() {
    const [owner] = await ethers.getSigners();
    //create pools
    const usdt = getTokens("USDT")["address"];
    const configuration = 0;//TODO:should be assgined to a reasonable configuration
    const poolFactory = await getContract("PoolFactory");
    const poolInterestRateStrategy = await getContract("PoolInterestRateStrategy");

    await sendTxn(
        poolFactory.createPool(usdt, poolInterestRateStrategy.target, configuration),
        "poolFactory.createPool(usdt)"
    );

    //set pools configuration
    const config = await getContract("Config");
    const multicallArgs = [
        config.interface.encodeFunctionData("setPoolActive", [usdt, true]),
        config.interface.encodeFunctionData("setPoolFrozen", [usdt, false]),
        config.interface.encodeFunctionData("setPoolPaused", [usdt, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [usdt, true]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [usdt, 1000]), //10%
        config.interface.encodeFunctionData("setPoolUsd", [usdt, false]),
    ];
    await sendTxn(
        config.multicall(multicallArgs),
        "config.multicall"
    );

    //print pool 
    const pool= await getPool(usdt);
    //console.log('0x' + pool.configuration.toString(16));
    console.log(pool.configuration);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })