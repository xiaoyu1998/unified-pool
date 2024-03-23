// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../borrow/BorrowUtils.sol";

interface IPoolToken {
    function addCollateral(address account, uint256 amount) external;
    function balanceOfCollateral (address account) external view returns (uint256);
}
