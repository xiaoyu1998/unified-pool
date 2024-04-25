// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library LiquidationEventUtils {

    function emitPositionLiquidation(
        address eventEmitter,
        address liquidator,
        address underlyingAsset,
        address account,
        uint256 collateral,
        uint256 debt,
        uint256 price
    ) external {
        IEventEmitter(eventEmitter).emitPositionLiquidation(
            liquidator,
            underlyingAsset,
            account,
            collateral,
            debt,
            price
        );
    }

    function emitLiquidation(
        address eventEmitter,
        address liquidator,
        address account,
        uint256 healthFactor,
        uint256 healthFactorLiquidationThreshold,
        uint256 totalCollateralUsd,
        uint256 totalDebtUsd
    ) external {
        IEventEmitter(eventEmitter).emitLiquidation(
            liquidator,
            account,
            healthFactor,
            healthFactorLiquidationThreshold,
            totalCollateralUsd,
            totalDebtUsd
        );
    }
}
