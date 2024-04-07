// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../role/RoleModule.sol";
import "../utils/BasicMulticall.sol";
import "../pool/PoolConfigurationUtils.sol";
import "../pool/PoolUtils.sol";
import "../oracle/OracleStoreUtils.sol";

import "../utils/Printer.sol";

// @title Config
contract Config is ReentrancyGuard, RoleModule, BasicMulticall {
    using PoolConfigurationUtils for uint256;

    DataStore public immutable dataStore;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) {
        dataStore = _dataStore;
    }

    modifier onlyKeeper() {
        if (
            !roleStore.hasRole(msg.sender, Role.LIMITED_CONFIG_KEEPER) &&
            !roleStore.hasRole(msg.sender, Role.CONFIG_KEEPER)
        ) {
            revert Errors.Unauthorized(msg.sender, "LIMITED / CONFIG KEEPER");
        }

        _;
    }

    function setOracle(
        address underlyingAsset,
        address oracle
    ) external onlyConfigKeeper nonReentrant {
        OracleStoreUtils.set(address(dataStore), underlyingAsset, oracle);
    } 

    function setOracleDecimals(
        address underlyingAsset,
        uint256 precision
    ) external onlyConfigKeeper nonReentrant {
        OracleStoreUtils.setOracleDecimals(address(dataStore), underlyingAsset, precision);
    } 

    function setHealthFactorCollateralRateThreshold(
        address underlyingAsset,
        uint256 threshold
    ) external onlyConfigKeeper nonReentrant {
        dataStore.setUint(Keys.healthFactorCollateralRateThresholdKey(underlyingAsset), threshold);
    } 
    
    function setPoolActive(address underlyingAsset, bool active) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setActive(active);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    } 

    function setPoolFreeze(address underlyingAsset, bool freeze) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setFrozen(freeze);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    } 

    function setPoolPause(address underlyingAsset, bool paused) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setPaused(paused);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    }  

    function setPoolBorrowingEnabled(address underlyingAsset, bool enabled) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setBorrowingEnabled(enabled);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    } 

    function setPoolDecimals(address underlyingAsset, uint256 decimals) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setDecimals(decimals);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    } 

    function setPoolFeeFactor(address underlyingAsset, uint256 feeFactor) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setFeeFactor(feeFactor);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    } 

    function setPoolBorrowCapacity(address underlyingAsset, uint256 borrowCapacity) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setBorrowCapacity(borrowCapacity);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    } 

    function setPoolSupplyCapacity(address underlyingAsset, uint256 supplyCapacity) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(address(dataStore), key);
        configuration = configuration.setSupplyCapacity(supplyCapacity);
        PoolStoreUtils.setConfiguration(address(dataStore), key, configuration);
    } 

}
