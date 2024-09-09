// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

library Errors {
    error ErrorStep(address account, uint256 step);

    // Bank errors
    error SelfTransferNotSupported(address receiver);
    error InvalidNativeTokenSender(address msgSender);

    // BaseRouter
    error CouldNotSendNativeToken(address receiver, uint256 amount);

    // PoolFactory errors
    error PoolAlreadyExists(address key, address poolToken);
    error CreateUserPoolClosed();
    error EmptyInterestRateStrategy();
    error EmptyConfiguration();
    error EmptyUnderlyingAssetUsd();

    // PoolStoreUtils errors
    error PoolIsInactive(address pool);
    error PoolIsPaused(address pool);
    error PoolIsFrozen(address pool);
    error PoolIsNotBorrowing(address pool);
    error PoolIsNotUsd(address pool);
    error EmptyPool(address key);

    // PoolToken errors
    error InsufficientAvailableLiquidity(uint256 amount, uint256 availableLiquidity);

    // PoolInterestRateStrategy errors
    error InvalidOptimalUsageRate(uint256 optimalUsageRatio);

    // PoolConfigurationUtils errors
    error InvalidDecimals(uint256 decimals, uint256 MaxValidDecimals);
    error InvalidFeeFactor(uint256 feeFactor, uint256 MaxValidFeeFactor);
    error InvalidBorrowCapacity(uint256 borrowCapacity, uint256 MaxValidBorrowCapacity);
    error InvalidSupplyCapacity(uint256 supplyCapacity, uint256 MaxValidSupplyCapacity);

    // Oracle errors
    error EmptyPoolOracle(address underlyingAsset);
    error InvalidOraclePrice(address underlyingAsset, int256 price);

    // Position errors
    error InvalidPoolIndex(uint256 poolKeyId);
    error PositionNotFound(bytes32 key);

    // PositionUtils errors
    error EmptyCollateral();
    error EmptyPosition();
    error UsdNotHaveLongOperation();
    error UsdNotHaveShortOperation();
    error HealthFactorLowerThanLiquidationThreshold(uint256 healthFactor, uint256 healthFactorLiquidationThreshold);
    error HealthFactorHigherThanLiquidationThreshold(uint256 healthFactor, uint256 healthFactorCollateralRateThreshold);
    error HealthFactorLowerThanCollateralRateThreshold(uint256 healthFactor, uint256 healthFactorCollateralRateThreshold);

    // BorrowUtils, WithdrawUtils errors
    error EmptyBorrowAmounts();
    error BorrowCapacityExceeded(uint256 totalDebt, uint256 borrowCapacity);
    error InsufficientLiquidityForBorrow(uint256 amountToBorrow, uint256 availableLiquidity);

    // DepositUtils errors
    error EmptyDepositAmounts();

    // SupplyUtils errors
    error EmptySupplyAmounts();
    error SupplyCapacityExceeded(uint256 totalSupplyAddUnclaimedFeeAddAmount, uint256 supplyCapacity);

    // WithdrawUtils errors
    error EmptyWithdrawAmounts();
    error InsufficientUserBalance(uint256 amount, uint256 userBalance);

    // RepayUtils errors
    error EmptyRepayAmount();
    error UserDoNotHaveDebtInPool(address account, address poolKey);
    error InsufficientCollateralAmountForRepay(uint256 repayAmount, uint256 collateralAmount);

    // RedeemUtils errors
    error EmptyRedeemAmount();

    // DexUniswapV3 errors
    error TokenCanNotSwapWithSelf(address token);
    error TokenNotMatch(address pool, address token0, address token1, address token);
    error EmptyUniswapPool();

    // SwapUtils errors
    error SwapPoolsNotMatch(address pool0, address pool1);
    error EmptySwapAmount();
    error InsufficientDexLiquidity(uint256 avaiableDexAmount, uint256 amount);
    error InsufficientCollateralForSwap(uint256 swapNeedamountIn, uint256 collateralAmount);

    // CloseUtils errors
    error EmptyPositions(address account);
    error CollateralCanNotCoverDebt(uint256 collateralAmount, uint256 debtAmount);
    error UsdCollateralCanNotCoverDebt(uint256 usdCollateralAmount, uint256 usdCollateralAmountNeeded, uint256 debtAmount, address underlyingAsset);
    error ClosePercentageExceeding();

    // RoleModule errors
    error Unauthorized(address msgSender, string role);

    // RoleStore errors
    error ThereMustBeAtLeastOneRoleAdmin();
    error ThereMustBeAtLeastOneTimelockMultiSig();

    //token
    error EmptyBurnAmounts();
    error EmptyMintAmounts();
    error DebtTokenOperationNotSupported();
    error InsufficientCollateralAmount(uint256 amountToRemove, uint256 amountBalance);

    // TokenUtils errors
    error EmptyTokenTranferGasLimit(address token);
    error TokenTransferError(address token, address receiver, uint256 amount);
    error EmptyHoldingAddress();

    // AccountUtils errors
    error EmptyAccount();
    error EmptyReceiver();

    // OracleStoreUtils
    error EmptyUnderlyingAsset();
    error EmptyOracle();
    error InvalidOracleDecimals(uint256 oracleDecimals, uint256 MaxOracleDecimals);

    // DexStoreUtils
    error EmptyDex();

    // Array errors
    error CompactedArrayOutOfBounds(
        uint256[] compactedValues,
        uint256 index,
        uint256 slotIndex,
        string label
    );

    // FeeUtils
    error EmptyUnclaimedFee(address poool);

    // FeeStoreUtils
    error EmptyTreasury();

}
