// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IBorrowHandler.sol";
import "../borrow/BorrowUtils.sol";

// @title BorrowHandler
// @dev Contract to handle execution of borrow
contract BorrowHandler is IBorrowHandler, GlobalReentrancyGuard, RoleModule {
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {
        eventEmitter = _eventEmitter;
    }

    // @dev executes a borrow
    // @param params BorrowUtils.BorrowParams
    function executeBorrow(
        address account,
        BorrowUtils.BorrowParams calldata BorrowParams
    ) external globalNonReentrant onlyController {

        BorrowUtils.ExecuteBorrowParams memory params = BorrowUtils.ExecuteBorrowParams(
           address(dataStore),
           address(eventEmitter),
           BorrowParams.underlyingAsset,     
           BorrowParams.amount
        );

        return BorrowUtils.executeBorrow(account, params);
    }

}
