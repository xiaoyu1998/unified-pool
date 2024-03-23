// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../withdraw/WithdrawUtils.sol";

interface IWithdrawHandler {
    function executeWithdraw(address account, WithdrawUtils.WithdrawParams calldata params) external;
}
