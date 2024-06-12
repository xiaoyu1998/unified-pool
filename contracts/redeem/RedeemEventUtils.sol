// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library RedeemEventUtils {

    function emitRedeem(
        address eventEmitter,
        address underlyingAsset,
        address redeemer,
        address to,
        uint256 redeemAmount,
        uint256 collateral,
        uint256 debtScaled
    ) external {
        IEventEmitter(eventEmitter).emitRedeem(
            underlyingAsset,
            redeemer,
            to,
            redeemAmount,
            collateral,
            debtScaled
        );
    }

}
