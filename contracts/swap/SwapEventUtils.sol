// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library SwapEventUtils {

    function emitSwap(
        address eventEmitter,
        address underlyingAssetIn,
        address underlyingAssetOut,
        address account,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        uint256 collateralIn,
        uint256 debtScaledIn,
        uint256 collateralOut,
        uint256 debtScaledOut
    ) external {
        IEventEmitter(eventEmitter).emitSwap(
            underlyingAssetIn,
            underlyingAssetOut,
            account,
            amountIn,
            amountOut,
            fee,
            collateralIn,
            debtScaledIn,
            collateralOut,
            debtScaledOut
        );
    }

}
