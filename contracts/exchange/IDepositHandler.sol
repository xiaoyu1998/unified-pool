// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../deposit/DepositUtils.sol";

interface IDepositHandler {
    function executeDeposit(address account, DepositUtils.DepositParams calldata params) external returns (bytes32);
}
