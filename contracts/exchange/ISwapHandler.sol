// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../swap/SwapUtils.sol";

interface ISwapHandler {
    function executeSwap(address account, SwapUtils.SwapParams calldata params) external;
    function executeSwapExactOut(address account, SwapUtils.SwapParams calldata params) external;
}
