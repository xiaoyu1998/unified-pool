// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../error/Errors.sol";
import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../event/IEventEmitter.sol";
import "../utils/WadRayMath.sol";
import "../utils/PercentageMath.sol";

import "../utils/Printer.sol";

// @title FeeUtils
// @dev Library for fee actions
library FeeUtils {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using Pool for Pool.Props;

    function incrementFeeAmount(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
    ) internal pure {
        if (poolCache.feeFactor == 0) {
          return;
        }

        uint256 prevTotalDebt      = poolCache.currTotalScaledDebt.rayMul(poolCache.currBorrowIndex);
        uint256 currTotalDebt      = poolCache.currTotalScaledDebt.rayMul(poolCache.nextBorrowIndex);
        uint256 increaseTotalDebt  = currTotalDebt - prevTotalDebt;
        uint256 feeAmount          = increaseTotalDebt.percentMul(poolCache.feeFactor);
        pool.incrementFee(feeAmount.rayDiv(poolCache.nextLiquidityIndex));

    }

    // @dev claim fees for the specified market
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param pool the pool to claim fees for
    // @param treasury the treasury to receive the claimed fees
    function claimFees(
        address dataStore,
        address eventEmitter,
        address underlyingAsset,
        address treasury
    ) internal {
        address poolKey = Keys.poolKey(underlyingAsset);
        address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKey);
        uint256 scaledUnclaimedFee = PoolStoreUtils.getUnclaimedFee(dataStore, poolKey);
        if (scaledUnclaimedFee == 0){
            revert Errors.EmptyUnclaimedFee(poolKey);
        }

        uint256 liquidityIndex = PoolUtils.getPoolNormalizedLiquidityIndex(dataStore, poolKey);
        uint256 unclaimedFee = scaledUnclaimedFee.rayMul(liquidityIndex);

        IPoolToken(poolToken).mintToTreasury(unclaimedFee, liquidityIndex, treasury);
        PoolStoreUtils.setUnclaimedFee(dataStore, poolKey, 0);//clean unclaimed fee

        IEventEmitter(eventEmitter).emitClaimFees(
            underlyingAsset,
            scaledUnclaimedFee,
            liquidityIndex,
            unclaimedFee
        );
    }

}
