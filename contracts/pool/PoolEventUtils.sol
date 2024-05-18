// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library PoolEventUtils {

    function emitPoolUpdated(
        address eventEmitter,
        address underlyingAsset,
        uint256 liquidityRate,
        uint256 borrowRate,
        uint256 liquidityIndex,
        uint256 borrowIndex
    ) external {
        IEventEmitter(eventEmitter).emitPoolUpdated(
            underlyingAsset,
            liquidityRate,
            borrowRate,
            liquidityIndex,
            borrowIndex
        );
    }

}
