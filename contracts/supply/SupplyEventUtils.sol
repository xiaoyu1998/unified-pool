// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library SupplyEventUtils {

    function emitSupply(
        address eventEmitter,
        address underlyingAsset,
        address account,
        address to,
        uint256 supplyAmount
    ) external {
        IEventEmitter(eventEmitter).emitSupply(
            underlyingAsset,
            account,
            to,
            supplyAmount
        );
    }

}
