// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../role/RoleModule.sol";
import "../utils/BasicMulticall.sol";
import "../pool/PoolConfigurationUtils.sol";
import "../pool/PoolUtils.sol";
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

    function setHealthFactorCollateralRateThreshold(
        address underlyingAsset,
        uint256 threshold
    ) external onlyConfigKeeper nonReentrant {
        dataStore.setUint(Keys.healthFactorCollateralRateThresholdKey(underlyingAsset), threshold);
    } 
    
    function setPoolActive(address underlyingAsset, bool active) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, key);
        configuration = configuration.setActive(active);
        PoolStoreUtils.setConfiguration(dataStore, key, configuration);
    } 

    function setPoolFreeze(address underlyingAsset, bool freeze) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, key);
        configuration = configuration.setFrozen(freeze);
        PoolStoreUtils.setConfiguration(dataStore, key, configuration);
    } 

    function setPoolPause(address underlyingAsset, bool paused) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, key);
        configuration = configuration.setPaused(paused);
        PoolStoreUtils.setConfiguration(dataStore, key, configuration);
    }  

    function setPoolDecimals(address underlyingAsset, uint256 decimals) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, key);
        configuration = configuration.setDecimals(decimals);
        PoolStoreUtils.setConfiguration(dataStore, key, configuration);
    } 

    function setPoolFeeFactor(address underlyingAsset, uint256 feeFactor) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, key);
        configuration = configuration.setFeeFactor(feeFactor);
        PoolStoreUtils.setConfiguration(dataStore, key, configuration);
    } 

    function setPoolBorrowCapacity(address underlyingAsset, uint256 borrowCapacity) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, key);
        configuration = configuration.setBorrowCapacity(borrowCapacity);
        PoolStoreUtils.setConfiguration(dataStore, key, configuration);
    } 

    function setPoolSupplyCapacity(address underlyingAsset, uint256 supplyCapacity) external onlyConfigKeeper nonReentrant {
        address key = PoolUtils.getKey(underlyingAsset);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, key);
        configuration = configuration.setSupplyCapacity(supplyCapacity);
        PoolStoreUtils.setConfiguration(dataStore, key, configuration);
    } 

}
