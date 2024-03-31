// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/Keys.sol";
import "../data/DataStore.sol";

import "./Pool.sol";

// @title PoolStoreUtils
// @dev Library for Pool Storage functions
library PoolStoreUtils {
	using Pool for Pool.Props;

    bytes32 public constant POOL_KEY_ID                 = keccak256(abi.encode("POOL_KEY_ID"));
    bytes32 public constant POOL_LIQUIDITY_INDEX  = keccak256(abi.encode("POOL_LIQUIDITY_INDEX"));
    bytes32 public constant POOL_LIQUIDITY_RATE   = keccak256(abi.encode("POOL_LIQUIDITY_RATE"));
    bytes32 public constant POOL_BORROW_INDEX     = keccak256(abi.encode("POOL_BORROW_INDEX"));
    bytes32 public constant POOL_BORROW_RATE      = keccak256(abi.encode("POOL_BORROW_RATE"));
    bytes32 public constant POOL_UNDERLYING_TOKEN       = keccak256(abi.encode("POOL_UNDERLYING_TOKEN"));
    bytes32 public constant POOL_INTEREST_RATE_STRATEGY = keccak256(abi.encode("POOL_INTEREST_RATE_STRATEGY"));
    bytes32 public constant POOL_TOKEN                  = keccak256(abi.encode("POOL_TOKEN"));
    bytes32 public constant POOL_DEBT_TOKEN             = keccak256(abi.encode("POOL_DEBT_TOKEN"));
    bytes32 public constant POOL_CONFIGRATION   = keccak256(abi.encode("POOL_CONFIGRATION"));
    bytes32 public constant POOL_FEE_FACTOR     = keccak256(abi.encode("POOL_FEE_FACTOR"));
    bytes32 public constant POOL_TOTAL_FEE = keccak256(abi.encode("POOL_TOTAL_FEE"));
    bytes32 public constant POOL_UNCLAIMED_FEE = keccak256(abi.encode("POOL_UNCLAIMED_FEE"));
    bytes32 public constant POOL_LAST_UPDATE_TIME_STAMP = keccak256(abi.encode("POOL_LAST_UPDATE_TIME_STAMP"));

    function get(DataStore dataStore, address key) public view returns (Pool.Props memory) {
        Pool.Props memory pool;
        if (!dataStore.containsAddress(Keys.POOL_LIST, key)) {
            return pool;
        }

        pool.keyId = dataStore.getUint(
            keccak256(abi.encode(key, POOL_KEY_ID))
        );

        pool.liquidityIndex = dataStore.getUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX))
        );

        pool.liquidityRate = dataStore.getUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE))
        );

        pool.borrowIndex = dataStore.getUint(
            keccak256(abi.encode(key, POOL_BORROW_INDEX))
        );

        pool.borrowRate = dataStore.getUint(
            keccak256(abi.encode(key, POOL_BORROW_RATE))
        );

        pool.interestRateStrategy = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY))
        );

        pool.underlyingAsset = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN))
        );

        pool.poolToken = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_TOKEN))
        );

        pool.debtToken = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN))
        );

        pool.configuration = dataStore.getUint(
            keccak256(abi.encode(key, POOL_CONFIGRATION))
        );

        pool.feeFactor = dataStore.getUint(
            keccak256(abi.encode(key, POOL_FEE_FACTOR))
        );

        pool.totalFee = dataStore.getUint(
            keccak256(abi.encode(key, POOL_TOTAL_FEE))
        );

        pool.unclaimedFee = dataStore.getUint(
            keccak256(abi.encode(key, POOL_UNCLAIMED_FEE))
        );

        pool.lastUpdateTimestamp = dataStore.getUint(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP))
        );

        return pool;
    }

    function setKeyAsId(DataStore dataStore, address key)  external returns (uint256) {
        uint256 id = dataStore.incrementUint(POOL_KEY_ID, 1);
        dataStore.setAddress(keccak256(abi.encode(id, POOL_KEY_ID)), key);
        return id;
    }

    function getKeyFromId(DataStore dataStore, uint256 id)  public view returns (address) {
        return dataStore.getAddress(keccak256(abi.encode(id, POOL_KEY_ID)));
    }

    function getPoolById(DataStore dataStore, uint256 id)  public view returns (Pool.Props memory) {
        address key = dataStore.getAddress(keccak256(abi.encode(id, POOL_KEY_ID)));
        return get(dataStore, key);
    }

    function set(DataStore dataStore, address key,  Pool.Props memory pool) external {
        dataStore.addAddress(
            Keys.POOL_LIST,
            key
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_KEY_ID)),
            pool.keyId
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX)),
            pool.liquidityIndex
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE)),
            pool.liquidityRate
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_BORROW_INDEX)),
            pool.borrowIndex
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_BORROW_RATE)),
            pool.borrowRate
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY)),
            pool.interestRateStrategy
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN)),
            pool.underlyingAsset
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_TOKEN)),
            pool.poolToken
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN)),
            pool.debtToken
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_CONFIGRATION)),
            pool.configuration
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_FEE_FACTOR)),
            pool.feeFactor
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_TOTAL_FEE)),
            pool.totalFee
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_UNCLAIMED_FEE)),
            pool.unclaimedFee
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP)),
            pool.lastUpdateTimestamp
        );

    }

    function remove(DataStore dataStore, address key) external {
        if (!dataStore.containsAddress(Keys.POOL_LIST, key)) {
            revert Errors.PoolNotFound(key);
        }

        dataStore.removeAddress(
            Keys.POOL_LIST,
            key
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_KEY_ID))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_BORROW_INDEX))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_BORROW_RATE))
        ); 

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_TOKEN))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_CONFIGRATION))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_FEE_FACTOR))
        );
        
        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_TOTAL_FEE))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_UNCLAIMED_FEE))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP))
        );
    }

    function getPoolToken(DataStore dataStore, address key) external returns (uint256){
        return dataStore.getUint(
            keccak256(abi.encode(key, POOL_TOKEN))
        );       
    }

    function getDebtToken(DataStore dataStore, address key) external returns (uint256){
        return dataStore.getUint(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN))
        );       
    }

    function setConfiguration(DataStore dataStore, address key, uint256 poolConfigration) external {
        dataStore.setUint(
            keccak256(abi.encode(key, POOL_CONFIGRATION)),
            poolConfigration
        );        
    }

    function getConfiguration(DataStore dataStore, address key) external returns (uint256){
        return dataStore.getUint(
            keccak256(abi.encode(key, POOL_CONFIGRATION))
        );       
    }

    function getPoolCount(DataStore dataStore) internal view returns (uint256) {
        return dataStore.getAddressCount(Keys.POOL_LIST);
    }

    function getPoolKeys(DataStore dataStore, uint256 start, uint256 end) internal view returns (address[] memory) {
        return dataStore.getAddressValuesAt(Keys.POOL_LIST, start, end);
    }


}