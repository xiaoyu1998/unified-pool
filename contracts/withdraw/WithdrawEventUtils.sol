// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/IEventEmitter.sol";

library WithdrawEventUtils {

    function emitWithdraw(
        address eventEmitter,
        address underlyingAsset,
        address account,
        address to,
        uint256 withdrawAmount
    ) external {
        IEventEmitter(eventEmitter).emitWithdraw(
            underlyingAsset,
            account,
            to,
            withdrawAmount
        );
    }

}
