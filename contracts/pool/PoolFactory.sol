// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./DebtToken.sol";
import "./PoolToken.sol";
import "./Pool.sol";
import "./PoolStoreUtils.sol";
import "./chain/chain.sol";
// import "../event/EventEmitter.sol";
// import "../utils/Cast.sol";

// @title PoolFactory
// @dev Contract to create pools
contract PoolFactory is RoleModule {
    using Pool for Pool.Props;

    // using EventUtils for EventUtils.AddressItems;
    // using EventUtils for EventUtils.UintItems;
    // using EventUtils for EventUtils.IntItems;
    // using EventUtils for EventUtils.BoolItems;
    // using EventUtils for EventUtils.Bytes32Items;
    // using EventUtils for EventUtils.BytesItems;
    // using EventUtils for EventUtils.StringItems;

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
        bytes32 salt = keccak256(abi.encode(
            "UF_POOL",
            underlineTokenAddress
        ));

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

    // function emitPoolCreated(
    //     address poolToken,
    //     bytes32 salt,
    //     address indexToken,
    //     address longToken,
    //     address shortToken
    // ) internal {
    //     EventUtils.EventLogData memory eventData;

    //     eventData.addressItems.initItems(4);
    //     eventData.addressItems.setItem(0, "poolToken", poolToken);
    //     eventData.addressItems.setItem(1, "indexToken", indexToken);
    //     eventData.addressItems.setItem(2, "longToken", longToken);
    //     eventData.addressItems.setItem(3, "shortToken", shortToken);

    //     eventData.bytes32Items.initItems(1);
    //     eventData.bytes32Items.setItem(0, "salt", salt);

    //     eventEmitter.emitEventLog1(
    //         "PoolCreated",
    //         Cast.toBytes32(poolToken),
    //         eventData
    //     );
    // }
}
