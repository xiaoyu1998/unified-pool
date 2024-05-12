// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";

// @title EventEmitter
// @dev Contract to emit events
// This allows main events to be emitted from a single contract
contract EventEmitter is RoleModule {

    event Supply(
        address indexed pool,
        address indexed supplier,
        address indexed to,
        uint256 amount
    );

    event Withdraw(
        address indexed pool, 
        address indexed withdrawer, 
        address indexed to, 
        uint256 amount
    );

    event Deposit(
        address indexed pool,
        address indexed depositer,
        //address indexed to,
        uint256 amount
    );

    event Redeem(
        address indexed pool,
        address indexed redeemer,
        address indexed to,
        uint256 amount
    );

    event Borrow(
        address indexed pool,
        address indexed borrower,
        //address indexed to,
        uint256 amount,
        uint256 borrowRate
    );

    event Repay(
        address indexed pool,
        // address indexed to,
        address indexed repayer,
        uint256 amount,
        bool useCollateral
    );

    event Swap(
        address indexed underlyingAssetIn,
        address indexed underlyingAssetOut,
        address indexed account,
        uint256 amountIn,
        uint256 amountOut
    );

    event PositionLiquidation(
        address indexed liquidator,
        address indexed pool,
        address indexed account,
        uint256 collateral,
        uint256 debt,
        uint256 price
    );

    event Liquidation(
        address indexed liquidator,
        address indexed account,
        uint256 healthFactor,
        uint256 healthFactorLiquidationThreshold,
        uint256 totalCollateralUsd,
        uint256 totalDebtUsd
    );

    event ClosePosition(
        address indexed pool,
        address indexed poolUsd,
        address indexed account,
        uint256 collateral,
        uint256 debt,
        uint256 remainUsd
    );

    event Close(
        address indexed poolUsd,
        address indexed account,
        uint256 amountUsdStartClose,
        uint256 amountUsdAfterRepayAndSellCollateral,
        uint256 amountUsdAfterBuyCollateralAndRepay
    );


    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    // @dev emit a general event log
    // @param eventName the name of the event
    function emitSupply(
        address underlyingAsset,
        address account,
        address to,
        uint256 supplyAmount
    ) external onlyController {
        emit Supply(
            underlyingAsset,
            account,
            to,
            supplyAmount
        );
    }

    function emitWithdraw(
        address underlyingAsset,
        address account,
        address to,
        uint256 withdrawAmount
    ) external onlyController {
        emit Withdraw(
            underlyingAsset,
            account,
            to,
            withdrawAmount
        );
    }

    function emitDeposit(
        address underlyingAsset,
        address account,
        uint256 depositAmount
    ) external onlyController {
        emit Deposit(
            underlyingAsset,
            account,
            depositAmount
        );
    }

    function emitRedeem(
        address underlyingAsset,
        address account,
        address to,
        uint256 redeemAmount
    ) external onlyController {
        emit Redeem(
            underlyingAsset,
            account,
            to,
            redeemAmount
        );
    }

    function emitBorrow(
        address underlyingAsset,
        address account,
        uint256 borrowAmount,
        uint256 borrowRate
    ) external onlyController {
        emit Borrow(
            underlyingAsset,
            account,
            borrowAmount,
            borrowRate
        );
    }

    function emitRepay(
        address underlyingAsset,
        address repayer,
        uint256 repayAmount,
        bool useCollateral
    ) external onlyController {
        emit Repay(
            underlyingAsset,
            repayer,
            repayAmount,
            useCollateral
        );
    }

    function emitSwap(
        address underlyingAssetIn,
        address underlyingAssetOut,
        address account,
        uint256 amountIn,
        uint256 amountOut
    ) external onlyController {
        emit Swap(
            underlyingAssetIn,
            underlyingAssetOut,
            account,
            amountIn,
            amountOut
        );
    }

    function emitPositionLiquidation(
        address liquidator,
        address underlyingAsset,
        address account,
        uint256 collateral,
        uint256 debt,
        uint256 price
    ) external onlyController {
        emit PositionLiquidation(
            liquidator,
            underlyingAsset,
            account,
            collateral,
            debt,
            price
        );
    }

    function emitLiquidation(
        address liquidator,
        address account,
        uint256 healthFactor,
        uint256 healthFactorLiquidationThreshold,
        uint256 totalCollateralUsd,
        uint256 totalDebtUsd
    ) external onlyController {
        emit Liquidation(
            liquidator,
            account,
            healthFactor,
            healthFactorLiquidationThreshold,
            totalCollateralUsd,
            totalDebtUsd
        );
    }

    function emitClosePosition(
        address underlyingAsset,
        address underlyingAssetUsd,
        address account,
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 remainAmountUsd
    ) external onlyController {
        emit ClosePosition(
            underlyingAsset,
            underlyingAssetUsd,
            account,
            collateralAmount,
            debtAmount,
            remainAmountUsd
        );
    }

    function emitClose(
        address underlyingAssetUsd,
        address account,
        uint256 amountUsdStartClose,
        uint256 amountUsdAfterRepayAndSellCollateral,
        uint256 amountUsdAfterBuyCollateralAndRepay
    ) external onlyController {
        emit Close(
            underlyingAssetUsd,
            account,
            amountUsdStartClose,
            amountUsdAfterRepayAndSellCollateral,
            amountUsdAfterBuyCollateralAndRepay
        );
    }

}
