// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../supply/SupplyUtils.sol";

interface ISupplyHandler {
    function executeSupply(address account, SupplyUtils.SupplyParams calldata params) external returns (bytes32);
}
