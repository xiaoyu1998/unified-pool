// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../role/RoleModule.sol";
import "../utils/BasicMulticall.sol";
import "../pool/PoolConfigurationUtils.sol";
import "../pool/PoolUtils.sol";

// @title Config
contract Config is ReentrancyGuard, RoleModule, BasicMulticall {

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

    function setHealthFactorCollateralRateThreshold(
        uint256 threshold
    ) external onlyConfigKeeper nonReentrant {

        dataStore.setUint(Keys.HEALTH_FACTOR_COLLATERAL_RATE_THRESHOLD, threshold);
    } 
    
    function setPoolActive(address underlyingAsset, bool active) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 poolConfigration = PoolStoreUtils.getConfiguration(dataStore, key);
        PoolConfigurationUtils.setActive(poolConfigration, active);
        PoolStoreUtils.setConfiguration(dataStore, key, poolConfigration);
    } 

    function setPoolFreeze(address underlyingAsset, bool freeze) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 poolConfigration = PoolStoreUtils.getConfiguration(dataStore, key);
        PoolConfigurationUtils.setFrozen(poolConfigration, freeze);
        PoolStoreUtils.setConfiguration(dataStore, key, poolConfigration);
    } 

    function setPoolPause(address underlyingAsset, bool paused) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 poolConfigration = PoolStoreUtils.getConfiguration(dataStore, key);
        PoolConfigurationUtils.setPaused(poolConfigration, paused);
        PoolStoreUtils.setConfiguration(dataStore, key, poolConfigration);
    }  

    function setPoolDecimals(address underlyingAsset, uint256 decimals) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 poolConfigration = PoolStoreUtils.getConfiguration(dataStore, key);
        PoolConfigurationUtils.setDecimals(poolConfigration, decimals);
        PoolStoreUtils.setConfiguration(dataStore, key, poolConfigration);
    } 

    function setPoolFeeFactor(address underlyingAsset, uint256 feeFactor) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 poolConfigration = PoolStoreUtils.getConfiguration(dataStore, key);
        PoolConfigurationUtils.setFeeFactor(poolConfigration, feeFactor);
        PoolStoreUtils.setConfiguration(dataStore, key, poolConfigration);
    } 

    function setPoolBorrowCapacity(address underlyingAsset, uint256 borrowCapacity) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 poolConfigration = PoolStoreUtils.getConfiguration(dataStore, key);
        PoolConfigurationUtils.setBorrowCapacity(poolConfigration, borrowCapacity);
        PoolStoreUtils.setConfiguration(dataStore, key, poolConfigration);
    } 

    function setPoolSupplyCapacity(address underlyingAsset, uint256 supplyCapacity) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 poolConfigration = PoolStoreUtils.getConfiguration(dataStore, key);
        PoolConfigurationUtils.setSupplyCapacity(poolConfigration, supplyCapacity);
        PoolStoreUtils.setConfiguration(dataStore, key, poolConfigration);
    } 

}
