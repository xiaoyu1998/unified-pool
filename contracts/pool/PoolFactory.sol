// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

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
        address underlineTokenAddress,
        uint256 configration,
    ) external onlyPoolKeeper returns (Pool.Props memory) {
        bytes32 salt = PoolUtils.getPoolSalt(underlineTokenAddress);

        address existingPoolAddress = dataStore.getAddress(PoolStoreUtils.getPoolSaltHash(salt));
        if (existingPoolAddress != address(0)) {
            revert Errors.PoolAlreadyExists(salt, existingPoolAddress);
        }

        PoolToken poolToken = new PoolToken{salt: salt}(roleStore, dataStore);
        DebtToken debtToken = new DebtToken{salt: salt}(roleStore, dataStore);

        Pool.Props memory pool = Pool.Props(
        	underlineTokenAddress,
        	configration,
        	1,0,1,0,
            currentTimestamp(),
            address(poolToken),
            address(debtToken)
        );

        PoolStoreUtils.set(dataStore, address(poolToken), salt, pool);
        //emitPoolCreated(address(poolToken), salt, indexToken, longToken, shortToken);

        return pool;
    }

}
