// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library DepositEventUtils {

    function emitDeposit(
        address eventEmitter,
        address underlyingAsset,
        address account,
        uint256 depositAmount,
        uint256 collateral,
        uint256 debtScaled       
    ) external {
        IEventEmitter(eventEmitter).emitDeposit(
            underlyingAsset,
            account,
            depositAmount,
            collateral,
            debtScaled
        );
    }

}
