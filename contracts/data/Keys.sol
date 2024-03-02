// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

// @title Keys
// @dev Keys for values in the DataStore
library Keys {
    // @dev for a global reentrancy guard
    bytes32 public constant REENTRANCY_GUARD_STATUS = keccak256(abi.encode("REENTRANCY_GUARD_STATUS"));

    // @dev constant for user initiated cancel reason
    string public constant USER_INITIATED_CANCEL = "USER_INITIATED_CANCEL";

    // @dev key for the claimable fee amount
    bytes32 public constant CLAIMABLE_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_FEE_AMOUNT"));


    // @dev key for the claimable fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    function claimableFeeAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FEE_AMOUNT, market, token));
    }

}
