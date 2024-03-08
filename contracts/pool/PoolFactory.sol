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
        address underlineToken,
        address interestRateStrategy,
        uint256 configration,
    ) external onlyPoolKeeper returns (Pool.Props memory) {
        bytes32 salt = PoolUtils.getPoolSalt(underlineToken);

        address existingPool = PoolStoreUtils.getBySalt(dataStore, PoolStoreUtils.getPoolSaltHash(salt));
        if (existingPool != address(0)) {
            revert Errors.PoolAlreadyExists(salt, existingPool);
        }

        PoolToken poolToken = new PoolToken{salt: salt}(roleStore, dataStore);
        DebtToken debtToken = new DebtToken{salt: salt}(roleStore, dataStore);

        bytes32 poolKey = PoolUtils.getPoolKey(address(poolToken));

        Pool.Props memory pool = Pool.Props(
            PoolStoreUtils.setPoolKeyAsId(poolKey)
        	configration,
        	1,0,1,0,
            currentTimestamp(),
            underlineToken,
            interestRateStrategy,
            address(poolToken),
            address(debtToken),
        );

        PoolStoreUtils.set(dataStore, poolKey, salt, pool);
        //emitPoolCreated(address(poolToken), salt, indexToken, longToken, shortToken);

        return pool;
    }

}
