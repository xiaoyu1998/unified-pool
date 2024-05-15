
import { getContract, sendTxn } from "./deploy";
import { exchangeRouterModule } from "../ignition/modules/deployExchangeRouter"
import { createAsset, createUniswapV3 } from "./assetsDex";
import { usdtDecimals, usdtOracleDecimal, uniDecimals, uniOracleDecimal} from "./constants";

export async function deployFixture() {
    const chainId = 31337; // hardhat chain id
    const accountList = await ethers.getSigners();
    const [
        user0,
        user1,
        user2,
        user3,
        user4,
        user5,
        user6,
        user7,
        user8,
        signer0,
        signer1,
        signer2,
        signer3,
        signer4,
        signer5,
        signer6,
        signer7,
        signer8,
        signer9,
    ] = accountList;

    const { 
        roleStore, 
        dataStore, 
        router, 
        exchangeRouter, 
        reader, 
        eventEmitter, 
        config,
        poolFactory,
        poolInterestRateStrategy,
        poolStoreUtils,
        positionStoreUtils
    } = await ignition.deploy(exchangeRouterModule);

    const usdt = await createAsset(
        user0,
        config, 
        "Tether", 
        "USDT", 
        100000000, 
        usdtDecimals,  
        usdtOracleDecimal, 
        1
    );
    const uni = await createAsset(
        user0, 
        config, 
        "UNI", 
        "UNI", 
        10000000, 
        uniDecimals, 
        uniOracleDecimal, 
        8
    );
    await createUniswapV3(
        user0, 
        config, 
        usdt, 
        usdtDecimals, 
        uni, 
        uniDecimals, 
        8
    );

    await sendTxn(
        poolFactory.createPool(usdt.target, poolInterestRateStrategy.target, 0),
        "poolFactory.createPool(usdt)"
    );
    await sendTxn(
        poolFactory.createPool(uni.target, poolInterestRateStrategy.target, 0),
        "poolFactory.createPool(uni)"
    ); 

    const usdtPool = await reader.getPool(dataStore.target, usdt.target);
    const uniPool = await reader.getPool(dataStore.target, uni.target);

    return {
      accountList,
      accounts: {
          user0,
          user1,
          user2,
          user3,
          user4,
          user5,
          user6,
          user7,
          user8,
          signer0,
          signer1,
          signer2,
          signer3,
          signer4,
          signer5,
          signer6,
          signer7,
          signer8,
          signer9,
          signers: [signer0, signer1, signer2, signer3, signer4, signer5, signer6],
      },
      contracts: {
          roleStore,
          dataStore,
          router,
          exchangeRouter,
          reader,
          dataStore,
          eventEmitter,
          config,
          poolFactory,
          configStoreUtils
      },
      assets: {
          usdt,
          uni
      },
      pools: {
          usdtPool,
          uniPool
      },
      //props: { signerIndexes: [0, 1, 2, 3, 4, 5, 6], executionFee: "1000000000000000" },
    };
}
