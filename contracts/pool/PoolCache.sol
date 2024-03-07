// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;


library PoolCache {

    struct Props {
        uint256 currTotalReserve;
        uint256 nextTotalReserve;
        uint256 currTotalCollateral;
        uint256 nextTotalCollateral;
        uint256 currTotalScaledDebt;
        uint256 nextTotalScaledDebt;

        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currLiquidityRate;
        uint256 currBorrowIndex;
        uint256 nextBorrowIndex;
        uint256 currBorrowRate;

        address poolToken;
        address debtToken;

        uint256 lastUpdateTimestamp;
        uint256 poolConfigration;
        uint256 poolFeeFactor;
    }

}
