
import { getContract, sendTxn } from "./deploy";
import { exchangeRouterModule } from "../ignition/modules/deployExchangeRouter"
import { createAsset, createUniswapV3 } from "./assetsDex";
import { expandDecimals } from "./math"
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
        positionStoreUtils,
        oracleStoreUtils,
        dexStoreUtils
    } = await ignition.deploy(exchangeRouterModule);

    const [usdt, usdtOracle] = await createAsset(
        user0,
        config, 
        "Tether", 
        "USDT", 
        100000000, 
        usdtDecimals,  
        usdtOracleDecimal, 
        1
    );
    const [uni, uniOracle] = await createAsset(
        user0, 
        config, 
        "UNI", 
        "UNI", 
        10000000, 
        uniDecimals, 
        uniOracleDecimal, 
        8
    );

    const usdtBalanceUser1 = expandDecimals(10000000, usdtDecimals);
    const uniBalanceUser1 = expandDecimals(1000000, uniDecimals);

    await usdt.transfer(user1, usdtBalanceUser1);
    await uni.transfer(user1, uniBalanceUser1);

    const dex = await createUniswapV3(
        user0, 
        config, 
        usdt, 
        usdtDecimals, 
        uni, 
        uniDecimals, 
        8
    );

    await poolFactory.createPool(usdt.target, poolInterestRateStrategy.target, 0);
    await poolFactory.createPool(uni.target, poolInterestRateStrategy.target, 0);
    const usdtPool = await reader.getPool(dataStore.target, usdt.target);
    const uniPool = await reader.getPool(dataStore.target, uni.target);
    
    //config pools
    const multicallArgs = [
        config.interface.encodeFunctionData("setHealthFactorLiquidationThreshold", [expandDecimals(110, 25)]),//110%
        config.interface.encodeFunctionData("setDebtMultiplierFactorForRedeem", [expandDecimals(2, 27)]),//2x
        config.interface.encodeFunctionData("setPoolActive", [usdt.target, true]),
        config.interface.encodeFunctionData("setPoolFrozen", [usdt.target, false]),
        config.interface.encodeFunctionData("setPoolPaused", [usdt.target, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [usdt.target, true]),
        config.interface.encodeFunctionData("setPoolDecimals", [usdt.target, usdtDecimals]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [usdt.target, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [usdt.target, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [usdt.target, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolUsd", [usdt.target, true]),
        config.interface.encodeFunctionData("setPoolActive", [uni.target, true]),
        config.interface.encodeFunctionData("setPoolFrozen", [uni.target, false]),
        config.interface.encodeFunctionData("setPoolPaused", [uni.target, false]),
        config.interface.encodeFunctionData("setPoolBorrowingEnabled", [uni.target, true]),
        config.interface.encodeFunctionData("setPoolDecimals", [uni.target, uniDecimals]),
        config.interface.encodeFunctionData("setPoolFeeFactor", [uni.target, 10]), //1/1000
        config.interface.encodeFunctionData("setPoolBorrowCapacity", [uni.target, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolSupplyCapacity", [uni.target, expandDecimals(1, 8)]),//100,000,000
        config.interface.encodeFunctionData("setPoolUsd", [uni.target, false]),
    ];
    await config.multicall(multicallArgs);

    //supply
    const usdtSupplyAmount = expandDecimals(10000000, usdtDecimals);
    await usdt.approve(router.target, usdtSupplyAmount);
    const uniSupplyAmount = expandDecimals(1000000, uniDecimals);
    await uni.approve(router.target, uniSupplyAmount);
    const usdtParams: SupplyUtils.SupplyParamsStruct = {
        underlyingAsset: usdt.target,
        to: user0.address,
    };
    const uniParams: SupplyUtils.SupplyParamsStruct = {
        underlyingAsset: uni.target,
        to: user0.address,
    };
    const multicallArgs2 = [
        exchangeRouter.interface.encodeFunctionData("sendTokens", [usdt.target, usdtPool.poolToken, usdtSupplyAmount]),
        exchangeRouter.interface.encodeFunctionData("executeSupply", [usdtParams]),
        exchangeRouter.interface.encodeFunctionData("sendTokens", [uni.target, uniPool.poolToken, uniSupplyAmount]),
        exchangeRouter.interface.encodeFunctionData("executeSupply", [uniParams]),
    ];
    await exchangeRouter.multicall(multicallArgs2);

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
          poolStoreUtils,
          positionStoreUtils,
          oracleStoreUtils,
          dexStoreUtils
      },
      assets: {
          usdt,
          uni,
          usdtOracle,
          uniOracle
      },
      pools: {
          usdtPool,
          uniPool
      },
      dexes: {
          dex
      },
      balances: {
        usdtBalanceUser1,
        uniBalanceUser1,
        usdtSupplyAmount,
        uniSupplyAmount
      },
      //props: { signerIndexes: [0, 1, 2, 3, 4, 5, 6], executionFee: "1000000000000000" },
    };
}
