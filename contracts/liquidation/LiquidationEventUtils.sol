// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../event/IEventEmitter.sol";

library LiquidationEventUtils {

    function emitLiquidation(
        address eventEmitter,
        address underlyingAsset,
        address account,
        uint256 collateral,
        uint256 debt,
        uint256 price
    ) external {
        IEventEmitter(eventEmitter).emitLiquidation(
            underlyingAsset,
            account,
            collateral,
            debt,
            price
        );
    }

    function emitHealthFactorLowerThanLiquidationThreshold(
        address eventEmitter,
        address account,
        uint256 healthFactor,
        uint256 healthFactorLiquidationThreshold,
        uint256 totalCollateralUsd,
        uint256 totalDebtUsd
    ) external {
        IEventEmitter(eventEmitter).emitHealthFactorLowerThanLiquidationThreshold(
            account,
            healthFactor,
            healthFactorLiquidationThreshold,
            totalCollateralUsd,
            totalDebtUsd
        );
    }
}
