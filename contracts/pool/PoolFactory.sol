// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../role/RoleModule.sol";
import "../data/DataStore.sol";
import "../error/Errors.sol";

import "./Pool.sol";
import "./PoolStoreUtils.sol";
import "./PoolConfigurationUtils.sol";
import "./PoolUtils.sol";
import "../token/PoolToken.sol";
import "../token/DebtToken.sol";
import "../chain/Chain.sol";

import "../oracel/IPriceFeed.sol";
import "../oracel/OracleStoreUtils.sol";
import "../dex/DexStoreUtils.sol";

// @title PoolFactory
// @dev Contract to create pools
contract PoolFactory is RoleModule {
    using Pool for Pool.Props;

    DataStore public immutable dataStore;
    address public immutable defaultInterestRateStrategy;
    address public immutable defaultDex;
    address public immutable defaultConfiguration;
    //address public immutable defaultOracle;
    address public immutable defaultUnderlyingAssetUsd;
    uint256 public immutable defaultUnderlyingAssetUsdDecimal;
    //uint256 public immutable defaultFeeFactor;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        address _interestRateStrategy,
        address _dex,
        address _configuration,
        address _oracle,
        address _underlyingAssetUsd,

    ) RoleModule(_roleStore) {
        dataStore = _dataStore;

        defaultInterestRateStrategy = _interestRateStrategy;
        defaultDex = _dex;
        defaultConfiguration = _configuration;
        //defaultOracle = _oracle;
        defaultUnderlyingAssetUsd = _underlyingAssetUsd;
        defaultUnderlyingAssetUsdDecimal = IERC20Metadata(_underlyingAssetUsd).decimals()
        //defaultFeeFactor = _feeFactor;
    }

    // @dev creates a pool
    function createPool(
        address underlyingAsset,
        address interestRateStrategy,
        uint256 configuration
    ) external onlyPoolKeeper returns (Pool.Props memory) {
        address poolKey = Keys.poolKey(underlyingAsset);

        Pool.Props memory existingPool = PoolStoreUtils.get(address(dataStore), poolKey);
        if (existingPool.poolToken != address(0)) {
            revert Errors.PoolAlreadyExists(poolKey, existingPool.poolToken);
        }

        PoolToken poolToken = new PoolToken(roleStore, dataStore, underlyingAsset);
        DebtToken debtToken = new DebtToken(roleStore, dataStore, underlyingAsset);

        Pool.Props memory pool = Pool.Props(
            PoolStoreUtils.setKeyAsId(address(dataStore), poolKey),
        	WadRayMath.RAY,
            0,
            WadRayMath.RAY,
            0,
            interestRateStrategy,
            underlyingAsset,
            address(poolToken),
            address(debtToken),
            configuration,
            0,
            0,
            Chain.currentTimestamp()
        );

        PoolStoreUtils.set(address(dataStore), poolKey, pool);
        return pool;
    }

    struct CreatePoolParams {
        address underlyingAsset;
        uint256 borrowCapacity;
        uint256 supplyCapacity;
    }

    // @dev creates a pool
    function createPoolByUser(
        CreatePoolParams calldata params
    ) external returns (Pool.Props memory) {
        address poolKey = Keys.poolKey(params.underlyingAsset);

        Pool.Props memory existingPool = PoolStoreUtils.get(address(dataStore), poolKey);
        if (existingPool.poolToken != address(0)) {
            revert Errors.PoolAlreadyExists(poolKey, existingPool.poolToken);
        }

        PoolToken poolToken = new PoolToken(roleStore, dataStore, params.underlyingAsset);
        DebtToken debtToken = new DebtToken(roleStore, dataStore, params.underlyingAsset);

        uint256 configuration = defaultConfiguration;
        uint256 decimal = IERC20Metadata(params.underlyingAsset).decimals();
        configuration = configuration.setDecimals(decimal);
        configuration = configuration.setBorrowCapacity(params.borrowCapacity);
        configuration = configuration.setBorrowCapacity(params.supplyCapacity);

        Pool.Props memory pool = Pool.Props(
            PoolStoreUtils.setKeyAsId(address(dataStore), poolKey),
            WadRayMath.RAY,
            0,
            WadRayMath.RAY,
            0,
            defaultInterestRateStrategy,
            params.underlyingAsset,
            address(poolToken),
            address(debtToken),
            configuration,
            0,
            0,
            Chain.currentTimestamp()
        );

        PoolStoreUtils.set(
            address(dataStore), 
            poolKey, 
            pool
        );

        OracleV3 oracle = new OracleV3(defaultDex, params.underlyingAsset, defaultUnderlyingAssetUsd);
        OracleStoreUtils.set(
            address(dataStore), 
            params.underlyingAsset, 
            oracle
        );
        OracleStoreUtils.setOracleDecimals(
            address(dataStore), 
            params.underlyingAsset, 
            oracle.oracleDecimals()
        );   

        DexStoreUtils.set(
            address(dataStore), 
            params.underlyingAsset, 
            defaultUnderlyingAssetUsd, 
            defaultDex
        );      
        return pool;
    }

}
