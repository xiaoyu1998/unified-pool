// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IBorrowHandler.sol";
import "../withdrawal/BorrowUtils.sol";

// @title BorrowHandler
// @dev Contract to handle execution of withdrawal
contract BorrowHandler is IBorrowHandler, GlobalReentrancyGuard, RoleModule {

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {

    }

    // @dev executes a withdrawal
    // @param withdrawalParams BorrowUtils.BorrowParams
    function executeBorrow(
        address account,
        BorrowUtils.BorrowParams calldata withdrawalParams
    ) external nonReentrant returns (bytes32){

        BorrowUtils.ExecuteBorrowParams memory params = BorrowUtils.ExecuteBorrowParams{
           dataStore,
           withdrawalParams.poolTokenAddress;        
           // withdrawalParams.asset,
           withdrawalParams.amount,
           withdrawalParams.receiver
        };

        return BorrowUtils.executeBorrow(account, params);
    }

}
