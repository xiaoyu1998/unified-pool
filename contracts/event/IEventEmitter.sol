// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IEventEmitter {

    function emitSupply(
        address underlyingAsset,
        address account,
        address to,
        uint256 SupplyAmount
    ) external;

    function emitWithdraw(
        address underlyingAsset,
        address account,
        address to,
        uint256 withdrawAmount
    ) external;

    function emitDeposit(
        address underlyingAsset,
        address account,
        uint256 depositAmount,
        uint256 collateral,
        uint256 debtScaled
    ) external;

    function emitRedeem(
        address underlyingAsset,
        address account,
        address to,
        uint256 redeemAmount,
        uint256 collateral,
        uint256 debtScaled
    ) external;

    function emitBorrow(
        address underlyingAsset,
        address account,
        uint256 borrowAmount,
        uint256 borrowRate,
        uint256 collateral,
        uint256 debtScaled
    ) external;

    function emitRepay(
        address underlyingAsset,
        address repayer,
        uint256 repayAmount,
        bool useCollateral,
        uint256 collateral,
        uint256 debtScaled
    ) external;

    function emitSwap(
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
    ) external;

    function emitPositionLiquidation(
        address liquidator,
        address underlyingAsset,
        address account,
        uint256 collateral,
        uint256 debt,
        uint256 price
    ) external;

    function emitLiquidation(
        address liquidator,
        address account,
        uint256 healthFactor,
        uint256 healthFactorLiquidationThreshold,
        uint256 totalCollateralUsd,
        uint256 totalDebtUsd 
    ) external;

    function emitClosePosition(
        address underlyingAsset,
        address underlyingAssetUsd,
        address account,
        // uint256 collateralAmount,
        uint256 collateralAmountToSell,
        // uint256 debtAmount,
        uint256 debtAmountClosed,
        uint256 remainAmount,
        uint256 remainAmountUsd,
        uint256 collateralUsd,
        uint256 debtScaledUsd
    ) external;

    function emitClose(
        address underlyingAssetUsd,
        address account,
        uint256 amountUsdStartClose,
        uint256 amountUsdAfterRepayAndSellCollateral,
        uint256 amountUsdAfterBuyCollateralAndRepay
    ) external;

    function emitPoolUpdated(
        address underlyingAsset,
        uint256 liquidityRate,
        uint256 borrowRate,
        uint256 liquidityIndex,
        uint256 borrowIndex
    ) external;

    function emitClaimFees(
        address underlyingAsset,
        uint256 scaledUnclaimedFee,
        uint256 liquidityIndex,
        uint256 unclaimedFee
    ) external;

}
