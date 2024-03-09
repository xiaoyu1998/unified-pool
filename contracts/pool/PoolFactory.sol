// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "./DebtToken.sol";
import "./PoolToken.sol";
import "./Pool.sol";
import "./PoolStoreUtils.sol";
import "./PoolUtils.sol";
import "./chain/chain.sol";
// @title PoolFactory
// @dev Contract to create pools
contract PoolFactory is RoleModule {
    using Pool for Pool.Props;

    DataStore public immutable dataStore;
    //IPoolInterestRateStrate public immutable poolInterestRateStrate
    // EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        // EventEmitter _eventEmitter
    ) RoleModule(_roleStore) {
        dataStore = _dataStore;
        // eventEmitter = _eventEmitter;
    }

    // @dev creates a pool
    function createPool(
        address underlyingAsset,
        address interestRateStrategy,
        uint256 configration,
    ) external onlyPoolKeeper returns (Pool.Props memory) {
        bytes32 key = PoolUtils.getPoolKey(underlyingAsset);

        address existingPool = PoolStoreUtils.get(dataStore, key);
        if (existingPool != address(0)) {
            revert Errors.PoolAlreadyExists(underlyingAsset, existingPool);
        }

        PoolToken poolToken = new PoolToken(roleStore, dataStore, underlyingAsset);
        DebtToken debtToken = new DebtToken(roleStore, dataStore, underlyingAsset);

        Pool.Props memory pool = Pool.Props(
            PoolStoreUtils.setPoolKeyAsId(key)
        	configration,
        	1,0,1,0,
            currentTimestamp(),
            key,
            interestRateStrategy,
            address(poolToken),
            address(debtToken),
        );

        PoolStoreUtils.set(dataStore, key, pool);
        //emitPoolCreated(address(poolToken), salt, indexToken, longToken, shortToken);

        return pool;
    }

}
