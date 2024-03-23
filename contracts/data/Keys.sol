// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

// @title Keys
// @dev Keys for values in the DataStore
library Keys {
    // @dev key for the address of the wrapped native token
    bytes32 public constant WNT = keccak256(abi.encode("WNT"));

    // @dev for holding tokens that could not be sent out
    bytes32 public constant HOLDING_ADDRESS = keccak256(abi.encode("HOLDING_ADDRESS"));

    // @dev for a global pool list
    bytes32 public constant POOL_LIST = keccak256(abi.encode("POOL_LIST"));

    // @dev for a global pool salt
    bytes32 public constant POOL_SALT = keccak256(abi.encode("POOL_SALT"));


    // @dev for a global position list
    bytes32 public constant POSITION_LIST = keccak256(abi.encode("POSITION_LIST"));
    
    // @dev key for the account position list
    bytes32 public constant ACCOUNT_POSITION_LIST = keccak256(abi.encode("ACCOUNT_POSITION_LIST"));

    // @dev for a global reentrancy guard
    bytes32 public constant REENTRANCY_GUARD_STATUS = keccak256(abi.encode("REENTRANCY_GUARD_STATUS"));

    // @dev constant for user initiated cancel reason
    string public constant USER_INITIATED_CANCEL = "USER_INITIATED_CANCEL";

    // @dev key for the claimable fee amount
    bytes32 public constant CLAIMABLE_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_FEE_AMOUNT"));


    // @dev key for the oracle
    bytes32 public constant ORACLE = keccak256(abi.encode("ORACLE"));


    // @dev key for the Health Factor Collateral RateT hreshold
    bytes32 public constant HEALTH_FACTOR_COLLATERAL_RATE_THRESHOLD = keccak256(abi.encode("HEALTH_FACTOR_COLLATERAL_RATE_THRESHOLD"));

    // @dev key for the amount of gas to forward for token transfers
    bytes32 public constant TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("TOKEN_TRANSFER_GAS_LIMIT"));

    // @dev key for the amount of gas to forward for native token transfers
    bytes32 public constant NATIVE_TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("NATIVE_TOKEN_TRANSFER_GAS_LIMIT"));


    // @dev key for the account position list
    // @param account the account for the list
    function accountPositionListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_POSITION_LIST, account));
    }

    // @dev key for the claimable fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    function claimableFeeAmountKey(address pool, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FEE_AMOUNT, pool, token));
    }

    // @dev key for gas to forward for token transfer
    // @param the token to check
    // @return key for gas to forward for token transfer
    function tokenTransferGasLimit(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOKEN_TRANSFER_GAS_LIMIT,
            token
        ));
   }

}
