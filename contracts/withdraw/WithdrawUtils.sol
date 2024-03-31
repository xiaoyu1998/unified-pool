// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";


// @title WithdrawUtils
// @dev Library for withdraw functions, to help with the withdrawing of liquidity
// into a market in return for market tokens
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
        DataStore dataStore;
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    // @dev executes a widthdraw
    // @param account the withdrawing account
    // @param params ExecuteWithdrawParams
    function executeWithdraw(address account, ExecuteWithdrawParams calldata params) external {
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        PoolCache.Props memory poolCache =  PoolUtils.cache(pool);
        PoolUtils.updateStateBetweenTransactions(pool, poolCache);

        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        uint256 userBalance = poolToken.scaledBalanceOf(account).rayMul(poolCache.nextLiquidityIndex);
        uint256 amountToWithdraw = params.amount;
        if (amountToWithdraw > userBalance) { //withdraw user balance
            amountToWithdraw = userBalance;
        }

        WithdrawUtils.validateWithdraw(
            poolCache, 
            amountToWithdraw, 
            userBalance
        );

        PoolUtils.updateInterestRates(
            pool,
            poolCache, 
            params.underlyingAsset, 
            0, 
            amountToWithdraw
        );

        PoolStoreUtils.set(
            params.dataStore, 
            params.underlyingAsset, 
            pool
        );

        poolToken.burn(
            account, 
            params.to, 
            amountToWithdraw, 
            poolCache.nextLiquidityIndex
        );
        poolToken.syncUnderlyingAssetBalance();
    }


    // @notice Validates a withdraw action.
    // @param poolCache The cached data of the pool
    // @param amount The amount to be withdrawn
    // @param userBalance The balance of the user   
    function validateWithdraw(
        PoolCache.Props memory poolCache,
        uint256 amount,
        uint256 userBalance
    ) internal view{
        if (amount == 0) { 
            revert Errors.EmptyWithdrawAmounts(); 
        }

        if (amount > userBalance) {
            revert Errors.InsufficientUserBalance(amount, userBalance);
        }

        (
            bool isActive,
            , 
            bool isPaused,
        ) = poolCache.configuration.getFlags();

        if (!isActive) { revert Errors.PoolIsInactive(); }  
        if (isPaused)  { revert Errors.PoolIsPaused();   }  

        uint256 availableLiquidity = IPoolToken(poolCache.poolToken).availableLiquidity();
        if (amount > availableLiquidity) {
            revert Errors.InsufficientAvailableLiquidity(amount, availableLiquidity);
        } 
      }
    
}
