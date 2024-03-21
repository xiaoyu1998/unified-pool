// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

library Errors {
    error ErrorToReplace();

    // BorrowUtils errors
    error PoolIsInactive();
    error PoolIsPaused();
    error PoolIsFrozen();
    error PoolIsNotEnabled();
    error PoolIsNotEnabled();
    error CollateralBalanceIsZero();
    error CollateralCanNotCoverNewBorrow(uint256 userTotalCollateralInUsd, uint256 userTotalDebtInUsd, uint256 amountToBorrowInUsd, uint256 healthFactorCollateralRateThreshold);


    //PositionUtils errors
     error EmptyPosition();


    // PoolFactory errors
    error PoolAlreadyExists(bytes32 salt, address existingPoolAddress);

    // PoolStoreUtils errors
    error PoolNotFound(address key);

    // SupplyUtils errors
    error EmptySupplyAmounts();

    // PoolInterestRateStrategy errors
    error InvalidOptimalUsageRate(uint256 optimalUsageRatio);



    // RoleModule errors
    error Unauthorized(address msgSender, string role);

    // RoleStore errors
    error ThereMustBeAtLeastOneRoleAdmin();
    error ThereMustBeAtLeastOneTimelockMultiSig();

    //token
    error EmptyBurnAmounts();
    error EmptyMintAmounts();

}
