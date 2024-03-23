// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;


library PoolCache {

    struct Props {
        // uint256 TotalReserve;
        // uint256 TotalCollateral;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currLiquidityRate;
        uint256 currBorrowIndex;
        uint256 nextBorrowIndex;
        uint256 currBorrowRate;

        uint256 currTotalScaledDebt;
        uint256 nextTotalScaledDebt;

        address underlyingAsset;
        address poolToken;
        address debtToken;

        uint256 configuration;
        uint256 feeFactor;
        uint256 totalFee;
        uint256 unclaimedFee;
        uint256 lastUpdateTimestamp;
    }

}
