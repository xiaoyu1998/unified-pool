// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";

import "./WithdrawEventUtils.sol";

// @title WithdrawUtils
// @dev Library for withdraw functions, to help with the withdrawing of liquidity
// from a pool in return for underlying tokens
library WithdrawUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct WithdrawParams {
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    struct ExecuteWithdrawParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    // @dev executes a widthdraw
    // @param account the withdrawing account
    // @param params ExecuteWithdrawParams
    function executeWithdraw(address account, ExecuteWithdrawParams calldata params) external {
        (   Pool.Props memory pool,
            PoolCache.Props memory poolCache,
            address poolKey,
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        uint256 userBalance = poolToken.scaledBalanceOf(account).rayMul(poolCache.nextLiquidityIndex);
        uint256 amountToWithdraw = params.amount;
        if (amountToWithdraw > userBalance) { //withdraw user balance
            amountToWithdraw = userBalance;
        }

        uint256 unclaimedFee = poolCache.unclaimedFee.rayMul(
            poolCache.nextBorrowIndex
        );

        uint256 availableLiquidity = IPoolToken(pool.poolToken).availableLiquidity(unclaimedFee);
        if (amountToWithdraw > availableLiquidity) {
            amountToWithdraw = availableLiquidity;
        }

        WithdrawUtils.validateWithdraw(
            pool, 
            amountToWithdraw
        );

        poolToken.burn(//amountToWithdraw liquidity will be reduced
            account, 
            params.to, 
            amountToWithdraw, 
            poolCache.nextLiquidityIndex,
            unclaimedFee
        );

        PoolUtils.updateInterestRates(
            params.eventEmitter,
            pool,
            poolCache
        );

        PoolStoreUtils.set(
            params.dataStore, 
            poolKey, 
            pool
        );

        WithdrawEventUtils.emitWithdraw(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            params.to, 
            amountToWithdraw
        );
    }

    // @notice Validates a withdraw action.
    // @param pool The state of the pool
    // @param amount The amount to be withdrawn
    function validateWithdraw(
        Pool.Props memory pool,
        uint256 amount
    ) internal view{
        PoolUtils.validateConfigurationPool(pool, false);    

        if (amount == 0) { 
            revert Errors.EmptyWithdrawAmounts(); 
        }
        
      }
    
}
