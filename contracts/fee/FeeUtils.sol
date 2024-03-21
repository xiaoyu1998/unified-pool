// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

// import "../data/DataStore.sol";
// import "../data/Keys.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";

import "../utils/WadRayMath.sol";
import "../utils/PercentageMath.sol";

// @title FeeUtils
// @dev Library for fee actions
library FeeUtils {
    // using EventUtils for EventUtils.AddressItems;
    // using EventUtils for EventUtils.UintItems;
    // using EventUtils for EventUtils.IntItems;
    // using EventUtils for EventUtils.BoolItems;
    // using EventUtils for EventUtils.Bytes32Items;
    // using EventUtils for EventUtils.BytesItems;
    // using EventUtils for EventUtils.StringItems;

    // struct IncrementClaimableFeeAmountVars {
    //     uint256 prevTotalStableDebt;
    //     uint256 prevTotalVariableDebt;
    //     uint256 currTotalVariableDebt;
    //     uint256 cumulatedStableInterest;
    //     uint256 totalDebtAccrued;
    //     uint256 amountToMint;
    // }

    function incrementTotalFeeAmount(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
    ) external {
        if (poolCache.feeFactor == 0) {
          return;
        }

        uint256 prevTotalDebt      = poolCache.currScaledDebt.rayMul(poolCache.currBorrowIndex);
        uint256 currTotalDebt      = poolCache.currScaledDebt.rayMul(poolCache.nextBorrowIndex);
        uint256 IncreaseTotalDebt  = currTotalDebt - prevTotalDebt;
        uint256 feeAmount          = IncreaseTotalDebt.percentMul(poolCache.feeFactor);
        pool.incrementTatalFeeAmount(feeAmount.rayDiv(poolCache.nextLiquidityIndex));

    }

    // // @dev claim fees for the specified market
    // // @param dataStore DataStore
    // // @param eventEmitter EventEmitter
    // // @param market the market to claim fees for
    // // @param token the fee token
    // // @param receiver the receiver of the claimed fees
    // function claimFees(
    //     DataStore dataStore,
    //     EventEmitter eventEmitter,
    //     address market,
    //     address token,
    //     address receiver
    // ) internal returns (uint256) {
    //     AccountUtils.validateReceiver(receiver);

    //     bytes32 key = Keys.claimableFeeAmountKey(market, token);

    //     uint256 feeAmount = dataStore.getUint(key);
    //     dataStore.setUint(key, 0);

    //     MarketToken(payable(market)).transferOut(
    //         token,
    //         receiver,
    //         feeAmount
    //     );

    //     MarketUtils.validateMarketTokenBalance(dataStore, market);

    //     emitFeesClaimed(
    //         eventEmitter,
    //         market,
    //         receiver,
    //         feeAmount
    //     );

    //     return feeAmount;
    // }


    // function emitClaimableFeeAmountUpdated(
    //     EventEmitter eventEmitter,
    //     address market,
    //     address token,
    //     uint256 delta,
    //     uint256 nextValue,
    //     bytes32 feeType
    // ) internal {
    //     EventUtils.EventLogData memory eventData;

    //     eventData.addressItems.initItems(2);
    //     eventData.addressItems.setItem(0, "market", market);
    //     eventData.addressItems.setItem(1, "token", token);

    //     eventData.uintItems.initItems(2);
    //     eventData.uintItems.setItem(0, "delta", delta);
    //     eventData.uintItems.setItem(1, "nextValue", nextValue);

    //     eventData.bytes32Items.initItems(1);
    //     eventData.bytes32Items.setItem(0, "feeType", feeType);

    //     eventEmitter.emitEventLog2(
    //         "ClaimableFeeAmountUpdated",
    //         Cast.toBytes32(market),
    //         feeType,
    //         eventData
    //     );
    // }

    // function emitFeesClaimed(
    //     EventEmitter eventEmitter,
    //     address market,
    //     address receiver,
    //     uint256 feeAmount
    // ) internal {
    //     EventUtils.EventLogData memory eventData;

    //     eventData.addressItems.initItems(2);
    //     eventData.addressItems.setItem(0, "market", market);
    //     eventData.addressItems.setItem(1, "receiver", receiver);

    //     eventData.uintItems.initItems(1);
    //     eventData.uintItems.setItem(0, "feeAmount", feeAmount);

    //     eventEmitter.emitEventLog1(
    //         "FeesClaimed",
    //         Cast.toBytes32(market),
    //         eventData
    //     );
    // }

}
