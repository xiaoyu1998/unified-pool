// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../borrow/BorrowUtils.sol";

interface IBorrowHandler {
    function executeBorrow(address account, BorrowUtils.BorrowParams calldata params) external;
}
