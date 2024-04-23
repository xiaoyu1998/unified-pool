// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../liquidation/LiquidationUtils.sol";

interface ILiquidationHandler {
    function executeLiquidation(address account, LiquidationUtils.LiquidationParams calldata params) external;
}
