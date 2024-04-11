// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library RepayEventUtils {

    function emitRepay(
        address eventEmitter,
        address underlyingAsset,
        address repayer,
        uint256 repayAmount,
        bool useCollateral
    ) external {
        IEventEmitter(eventEmitter).emitRepay(
            underlyingAsset,
            repayer,
            repayAmount,
            useCollateral
        );
    }

}
