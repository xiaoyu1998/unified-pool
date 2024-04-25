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
        uint256 depositAmount
    ) external;

    function emitRedeem(
        address underlyingAsset,
        address account,
        address to,
        uint256 redeemAmount
    ) external;

    function emitBorrow(
        address underlyingAsset,
        address account,
        uint256 borrowAmount,
        uint256 borrowRate
    ) external;

    function emitRepay(
        address underlyingAsset,
        address repayer,
        uint256 repayAmount,
        bool useCollateral
    ) external;

    function emitSwap(
        address underlyingAssetIn,
        address underlyingAssetOut,
        address account,
        uint256 amountIn,
        uint256 amountOut
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

}
