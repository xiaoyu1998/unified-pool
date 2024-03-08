// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/Keys.sol";
import "../data/DataStore.sol";

import "./Pool.sol";

// @title PoolStoreUtils
// @dev Library for Pool Storage functions
library PoolStoreUtils {
	using Pool for Pool.Props;

    bytes32 public constant POOL_KEY_ID                 = keccak256(abi.encode("POOL_KEY_ID"));
    bytes32 public constant POOL_CONFIGRATION           = keccak256(abi.encode("POOL_CONFIGRATION"));
    bytes32 public constant POOL_LIQUIDITY_INDEX        = keccak256(abi.encode("POOL_LIQUIDITY_INDEX"));
    bytes32 public constant POOL_LIQUIDITY_RATE         = keccak256(abi.encode("POOL_LIQUIDITY_RATE"));
    bytes32 public constant POOL_BORROW_INDEX           = keccak256(abi.encode("POOL_BORROW_INDEX"));
    bytes32 public constant POOL_BORROW_RATE            = keccak256(abi.encode("POOL_BORROW_RATE"));
    bytes32 public constant POOL_LAST_UPDATE_TIME_STAMP = keccak256(abi.encode("POOL_LAST_UPDATE_TIME_STAMP"));
    bytes32 public constant POOL_UNCLAIM_POOL_FEE       = keccak256(abi.encode("POOL_UNCLAIM_POOL_FEE"));
    bytes32 public constant POOL_UNDERLYING_TOKEN       = keccak256(abi.encode("POOL_UNDERLYING_TOKEN"));
    bytes32 public constant POOL_INTEREST_RATE_STRATEGY = keccak256(abi.encode("POOL_INTEREST_RATE_STRATEGY"));
    bytes32 public constant POOL_TOKEN      = keccak256(abi.encode("POOL_TOKEN"));
    bytes32 public constant POOL_DEBT_TOKEN = keccak256(abi.encode("POOL_DEBT_TOKEN"));


    function setPoolKeyAsId(DataStore dataStore, bytes32 key)  public view returns (uint256) {
        uint256 id = dataStore.incrementInt(POOL_KEY_ID, 1);
        dataStore.setBytes32(keccak256(abi.encode(id, POOL_KEY_ID)), key);
        return id;
    }

    function getPoolKeyFromId(DataStore dataStore, uint256 id)  public view returns (bytes32) {
        return dataStore.getBytes3(keccak256(abi.encode(id, POOL_KEY_ID)));
    }


    function get(DataStore dataStore, bytes32 key) public view returns (Pool.Props memory) {
        Pool.Props memory pool;
        if (!dataStore.containsBytes32(Keys.POOL_LIST, key)) {
            return pool;
        }

        pool.setPoolKeyId(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_KEY_ID))
        ));

        pool.setConfigrationdat(Store.getAddress(
            keccak256(abi.encode(key, POOL_CONFIGRATION))
        ));

        pool.setLiquidityIndex(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX))
        ));

        pool.setLiquidityRate(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE))
        ));

        pool.setBorrowIndex(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_BORROW_INDEX))
        ));

        pool.setBorrowRate(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_BORROW_RATE))
        ));

        pool.lastUpdateTimestamp(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP))
        ));

        pool.setUnclaimPoolFee(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_UNCLAIM_POOL_FEE))
        ));

        pool.setUnderlyingToken(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN))
        ));

        pool.setInterestRateStrategy(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY))
        ));

        pool.setPoolToken(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_TOKEN))
        ));

        pool.setDebtTokeny(dataStore.getAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN))
        ));

        return pool;
    }

    function getBySalt(DataStore dataStore, bytes32 salt) external view returns (Pool.Props memory) {
        address key = dataStore.getBytes32(getPoolSaltHash(salt));
        return get(dataStore, key);
    }


    //function set(DataStore dataStore, address key, bytes32 salt, Pool.Props memory pool) external {
    function set(DataStore dataStore, bytes32 key, bytes32 salt, Pool.Props memory pool) external {
        dataStore.addBytes32(
            Keys.POOL_LIST,
            key
        );

        // the salt is based on the pool props while the key gives the pool's address
        // use the salt to store a reference to the key to allow the key to be retrieved
        // using just the salt value
        dataStore.setBytes32(
            getPoolSaltHash(salt),
            key
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_KEY_ID)),
            pool.poolKeyId()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_CONFIGRATION)),
            pool.configration()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_INDEX)),
            pool.liquidityIndex()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_LIQUIDITY_RATE)),
            pool.liquidityRate()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_BORROW_INDEX)),
            pool.borrowIndex()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_BORROW_RATE)),
            pool.borrowRate()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP)),
            pool.lastUpdateTimestamp()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POOL_UNCLAIM_POOL_FEE)),
            pool.unclaimPoolFee()
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN)),
            pool.underlyingToken()
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY)),
            pool.interestRateStrategy()
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_TOKEN)),
            pool.poolToken()
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN)),
            pool.debtToken()
        );
    }

    function remove(DataStore dataStore, bytes32 key) external {
        if (!dataStore.containsBytes32(Keys.POOL_LIST, key)) {
            revert Errors.PoolNotFound(key);
        }

        dataStore.removeBytes32(
            Keys.POOL_LIST,
            key
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_KEY_ID))
        );
        
        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_CONFIGRATION))
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

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_LAST_UPDATE_TIME_STAMP))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POOL_UNCLAIM_POOL_FEE))
        ); 

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_UNDERLYING_TOKEN))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_INTEREST_RATE_STRATEGY))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_TOKEN))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, POOL_DEBT_TOKEN))
        );
    }

    function getPoolSaltHash(bytes32 salt) internal pure returns (bytes32) {
        return keccak256(abi.encode(POOL_SALT, salt));
    }

    function getPoolCount(DataStore dataStore) internal view returns (uint256) {
        return dataStore.getAddressCount(Keys.POOL_LIST);
    }

    function getPoolKeys(DataStore dataStore, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        return dataStore.getAddressValuesAt(Keys.POOL_LIST, start, end);
    }


}