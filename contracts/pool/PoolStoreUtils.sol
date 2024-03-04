// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/Keys.sol";
import "../data/DataStore.sol";

import "./Pool.sol";

// @title PoolStoreUtils
// @dev Library for Pool Storage functions
library PoolStoreUtils {
	using Pool for Pool.Props;

    bytes32 public constant POOL_UNDERLYING_TOKEN_ADDRESS = keccak256(abi.encode("POOL_UNDERLYING_TOKEN_ADDRESS"));
    bytes32 public constant POOL_INTEREST_RATE_STRATEGY_ADDRESS = keccak256(abi.encode("POOL_INTEREST_RATE_STRATEGY_ADDRESS"));
    bytes32 public constant POOL_CONFIGRATION = keccak256(abi.encode("POOL_CONFIGRATION"));
    bytes32 public constant POOL_LIQUIDITY_INDEX = keccak256(abi.encode("POOL_LIQUIDITY_INDEX"));
    bytes32 public constant POOL_LIQUIDITY_RATE = keccak256(abi.encode("POOL_LIQUIDITY_RATE"));
    bytes32 public constant POOL_BORROW_INDEX = keccak256(abi.encode("POOL_BORROW_INDEX"));
    bytes32 public constant POOL_BORROW_RATE = keccak256(abi.encode("POOL_BORROW_RATE"));
    bytes32 public constant POOL_LAST_UPDATE_TIME_STAMP = keccak256(abi.encode("POOL_LAST_UPDATE_TIME_STAMP"));
    bytes32 public constant POOL_TOKEN_ADDRESS = keccak256(abi.encode("POOL_TOKEN_ADDRESS"));
    bytes32 public constant POOL_DEBT_TOKEN_ADDRESS = keccak256(abi.encode("POOL_DEBT_TOKEN_ADDRESS"));


    function get(DataStore dataStore, address key) public view returns (Pool.Props memory) {
        Pool.Props memory pool;
        if (!dataStore.containsAddress(Keys.POOL_LIST, key)) {
            return pool;
        }


        pool.underlyingTokenAddress = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN_ADDRESS))
        );

        pool.interestRateStrategyAddress = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY_ADDRESS))
        );

        pool.Configration = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_CONFIGRATION))
        );

        pool.liquidityIndex = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX))
        );

        pool.LiquidityRate = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE))
        );

        pool.borrowIndex = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_BORROW_INDEX))
        );

        pool.borrowRate = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_BORROW_RATE))
        );

        pool.lastUpdateTimestamp = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP))
        );

        pool.poolTokenAddress = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_TOKEN_ADDRESS))
        );

        pool.debtTokenAddress = dataStore.getAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN_ADDRESS))
        );

        return pool;
    }

    function getBySalt(DataStore dataStore, bytes32 salt) external view returns (Pool.Props memory) {
        address key = dataStore.getAddress(getPoolSaltHash(salt));
        return get(dataStore, key);
    }


    //function set(DataStore dataStore, address key, bytes32 salt, Pool.Props memory market) external {
    function set(DataStore dataStore, address key, bytes32 salt, Pool.Props memory market) external {
        dataStore.addAddress(
            Keys.POOL_LIST,
            key
        );

        // the salt is based on the market props while the key gives the market's address
        // use the salt to store a reference to the key to allow the key to be retrieved
        // using just the salt value
        dataStore.setAddress(
            getPoolSaltHash(salt),
            key
        );


        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN_ADDRESS)),
            market.underlyingTokenAddress
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY_ADDRESS)),
            market.interestRateStrategyAddress
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_CONFIGRATION)),
            market.Configration
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX)),
            market.liquidityIndex
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE)),
            market.LiquidityRate
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_BORROW_INDEX)),
            market.borrowIndex
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_BORROW_RATE)),
            market.borrowRate
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP)),
            market.lastUpdateTimestamp
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_TOKEN_ADDRESS)),
            market.poolTokenAddress
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN_ADDRESS)),
            market.debtTokenAddress
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

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN_ADDRESS))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY_ADDRESS))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_CONFIGRATION))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_BORROW_INDEX))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_BORROW_RATE))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_TOKEN_ADDRESS))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN_ADDRESS))
        );
    }

    function getPoolSaltHash(bytes32 salt) internal pure returns (bytes32) {
        return keccak256(abi.encode(POOL_SALT, salt));
    }

    function getPoolCount(DataStore dataStore) internal view returns (uint256) {
        return dataStore.getAddressCount(Keys.POOL_LIST);
    }

    function getPoolKeys(DataStore dataStore, uint256 start, uint256 end) internal view returns (address[] memory) {
        return dataStore.getAddressValuesAt(Keys.POOL_LIST, start, end);
    }


}