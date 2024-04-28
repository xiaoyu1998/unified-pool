// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../close/CloseUtils.sol";

interface ICloseHandler {
    //function executeClose(address account) external;
    function executeClosePosition(address account, CloseUtils.ClosePositionParams calldata params) external;
}
