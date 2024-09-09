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

struct CreatePoolParams {
    address underlyingAsset;
    uint256 borrowCapacity;
    uint256 supplyCapacity;
}

// @title PoolFactory
// @dev Contract to create pools
contract PoolFactory is RoleModule {
    using Pool for Pool.Props;
    using PoolConfigurationUtils for uint256;

    DataStore public immutable dataStore;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) {
        dataStore = _dataStore;
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

    struct CreatePoolByUserLocalVars {
        bool createUserPoolOpened;
        address interestRateStrategy;
        address dex;
        uint256 configuration;
        address underlyingAssetUsd;
        address poolKey;

        Pool.Props existingPool;
        PoolToken poolToken;
        DebtToken debtToken;

        uint256 config;
        uint256 decimals;
        Pool.Props pool;

        OracleDex oracle;
    }

    // @dev creates a pool
    function createPoolByUser(
        CreatePoolParams calldata params
    ) external returns (Pool.Props memory) {

        CreatePoolByUserLocalVars memory vars;

        //get settings
        vars.createUserPoolOpened = PoolStoreUtils.getCreateUserPoolOpen(address(dataStore));
        if (!vars.createUserPoolOpened){
            revert Errors.CreateUserPoolClosed();
        }
        vars.interestRateStrategy = PoolStoreUtils.getUserPoolInterestRateStrategy(address(dataStore));
        if (vars.interestRateStrategy == address(0)){
                revert Errors.EmptyInterestRateStrategy();
        }
        vars.dex = PoolStoreUtils.getUserPoolDex(address(dataStore));
        if (vars.dex == address(0)){
            revert Errors.EmptyDex();
        }
        vars.configuration = PoolStoreUtils.getUserPoolConfiguration(address(dataStore));
        if (vars.configuration == 0){
            revert Errors.EmptyConfiguration();
        }
        vars.underlyingAssetUsd = PoolStoreUtils.getUserPoolUnderlyingAssetUsd(address(dataStore));
        if (vars.underlyingAssetUsd == address(0)){
            revert Errors.EmptyUnderlyingAssetUsd();
        }

        //check pool
        vars.poolKey = Keys.poolKey(params.underlyingAsset);
        vars.existingPool = PoolStoreUtils.get(address(dataStore), vars.poolKey);
        if (vars.existingPool.poolToken != address(0)) {
            revert Errors.PoolAlreadyExists(vars.poolKey, vars.existingPool.poolToken);
        }

        vars.poolToken = new PoolToken(roleStore, dataStore, params.underlyingAsset);
        vars.debtToken = new DebtToken(roleStore, dataStore, params.underlyingAsset);

        vars.decimals = IERC20Metadata(params.underlyingAsset).decimals();
        vars.configuration = vars.configuration.setDecimals(vars.decimals);
        vars.configuration = vars.configuration.setBorrowCapacity(params.borrowCapacity);
        vars.configuration = vars.configuration.setBorrowCapacity(params.supplyCapacity);

        vars.pool = Pool.Props(
            PoolStoreUtils.setKeyAsId(address(dataStore), vars.poolKey),
            WadRayMath.RAY,
            0,
            WadRayMath.RAY,
            0,
            vars.interestRateStrategy,
            params.underlyingAsset,
            address(vars.poolToken),
            address(vars.debtToken),
            vars.configuration,
            0,
            0,
            Chain.currentTimestamp()
        );

        PoolStoreUtils.set(
            address(dataStore), 
            vars.poolKey, 
            vars.pool
        );

        vars.oracle = new OracleDex(vars.dex, params.underlyingAsset, vars.underlyingAssetUsd);
        OracleStoreUtils.set(
            address(dataStore), 
            params.underlyingAsset, 
            address(vars.oracle)
        );
        OracleStoreUtils.setOracleDecimals(
            address(dataStore), 
            params.underlyingAsset, 
            vars.oracle.decimals()
        );   
        DexStoreUtils.set(
            address(dataStore), 
            params.underlyingAsset, 
            vars.underlyingAssetUsd, 
            vars.dex
        );      
        return vars.pool;
    }

}
