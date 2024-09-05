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

import "../oracle/OracleDex.sol";
import "../oracle/OracleStoreUtils.sol";
import "../dex/DexStoreUtils.sol";

// @title PoolFactory
// @dev Contract to create pools
contract PoolFactory is RoleModule {
    using Pool for Pool.Props;
    using PoolConfigurationUtils for uint256;

    DataStore public immutable dataStore;

    //pool settings for create pool by user
    address public interestRateStrategy;
    address public dex;
    uint256 public configuration;
    address public underlyingAssetUsd;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) {
        dataStore = _dataStore;
    }

    function setInterestRateStrategy(
        address _interestRateStrategy
    ) external onlyPoolKeeper {
        interestRateStrategy = _interestRateStrategy;
    }

    function setDex(
        address _dex
    ) external onlyPoolKeeper {
        dex = _dex;
    }

    function setConfiguration(
        uint256 _configuration
    ) external onlyPoolKeeper {
        configuration = _configuration;
    }

    function setUnderlyingAssetUsd(
        address _underlyingAssetUsd
    ) external onlyPoolKeeper {
        underlyingAssetUsd = _underlyingAssetUsd;
    }

    // @dev creates a pool
    function createPool(
        address underlyingAsset,
        address _interestRateStrategy,
        uint256 _configuration
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
            _interestRateStrategy,
            underlyingAsset,
            address(poolToken),
            address(debtToken),
            _configuration,
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
        //validate
        if (interestRateStrategy == address(0)){
            revert Errors.EmptyInterestRateStrategy();
        }

        if (dex == address(0)){
            revert Errors.EmptyDex();
        }

        if (configuration == 0){
            revert Errors.EmptyConfiguration();
        }

        if (underlyingAssetUsd == address(0)){
            revert Errors.EmptyUnderlyingAssetUsd();
        }

        address poolKey = Keys.poolKey(params.underlyingAsset);

        Pool.Props memory existingPool = PoolStoreUtils.get(address(dataStore), poolKey);
        if (existingPool.poolToken != address(0)) {
            revert Errors.PoolAlreadyExists(poolKey, existingPool.poolToken);
        }

        PoolToken poolToken = new PoolToken(roleStore, dataStore, params.underlyingAsset);
        DebtToken debtToken = new DebtToken(roleStore, dataStore, params.underlyingAsset);

        uint256 config = configuration;
        uint256 decimals = IERC20Metadata(params.underlyingAsset).decimals();
        config = config.setDecimals(decimals);
        config = config.setBorrowCapacity(params.borrowCapacity);
        config = config.setBorrowCapacity(params.supplyCapacity);

        Pool.Props memory pool = Pool.Props(
            PoolStoreUtils.setKeyAsId(address(dataStore), poolKey),
            WadRayMath.RAY,
            0,
            WadRayMath.RAY,
            0,
            interestRateStrategy,
            params.underlyingAsset,
            address(poolToken),
            address(debtToken),
            config,
            0,
            0,
            Chain.currentTimestamp()
        );

        PoolStoreUtils.set(
            address(dataStore), 
            poolKey, 
            pool
        );

        OracleDex oracle = new OracleDex(dex, params.underlyingAsset, underlyingAssetUsd);
        OracleStoreUtils.set(
            address(dataStore), 
            params.underlyingAsset, 
            address(oracle)
        );
        OracleStoreUtils.setOracleDecimals(
            address(dataStore), 
            params.underlyingAsset, 
            oracle.decimals()
        );   

        DexStoreUtils.set(
            address(dataStore), 
            params.underlyingAsset, 
            underlyingAssetUsd, 
            dex
        );      
        return pool;
    }

}
