// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library CloseEventUtils {

    function emitClosePosition(
        address eventEmitter,
        address underlyingAsset,
        address underlyingAssetUsd,
        address account,
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 remainAmountUsd
    ) external {
        IEventEmitter(eventEmitter).emitClosePosition(
            underlyingAsset,
            underlyingAssetUsd,
            account,
            collateralAmount,
            debtAmount,
            remainAmountUsd
        );
    }

}
