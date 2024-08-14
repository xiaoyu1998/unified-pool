// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library CloseEventUtils {

    function emitClosePosition(
        address eventEmitter,
        address underlyingAsset,
        address underlyingAssetUsd,
        address account,
        // uint256 collateralAmount,
        uint256 collateralAmountToSell, 
        // uint256 debtAmount,
        uint256 debtAmountToClose,  
        uint256 remainAmount,    
        uint256 remainAmountUsd,
        uint256 collateralUsd,
        uint256 debtScaledUsd
    ) external {
        IEventEmitter(eventEmitter).emitClosePosition(
            underlyingAsset,
            underlyingAssetUsd,
            account,
            // collateralAmount,
            collateralAmountToSell,
            // debtAmount,
            debtAmountToClose,
            remainAmount,
            remainAmountUsd,
            debtScaledUsd,
            collateralUsd
        );
    }

    function emitClose(
        address eventEmitter,
        address underlyingAssetUsd,
        address account,
        uint256 amountUsdStartClose,
        uint256 amountUsdAfterRepayAndSellCollateral,
        uint256 amountUsdAfterBuyCollateralAndRepay
    ) external {
        IEventEmitter(eventEmitter).emitClose(
            underlyingAssetUsd,
            account,
            amountUsdStartClose,
            amountUsdAfterRepayAndSellCollateral,
            amountUsdAfterBuyCollateralAndRepay
        );
    }

}
