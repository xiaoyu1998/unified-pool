// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import './IPeripheryImmutableState.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override factory;

    constructor(address _factory) {
        factory = _factory;
        //WETH9 = _WETH9;
    }
}
