// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../close/CloseUtils.sol";

interface ICloseHandler {
    function executeClosePosition(address account, CloseUtils.ClosePositionParams calldata params) external;
    function executeClose(address account, CloseUtils.CloseParams calldata params) external;
}
