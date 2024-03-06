// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "../pool/pool.sol";
import "../pool/PoolConfigurationUtils.sol";


// @title DepositUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library DepositUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;

    struct DepositParams {
        address poolTokenAddress;
        //address asset;
        //uint256 amount;
        address receiver;
    }

    struct ExecuteDepositParams {
        DataStore dataStore;
        // EventEmitter eventEmitter;
        address poolTokenAddress;
       // address asset;
        //uint256 amount;
        address receiver;

    }

    // @dev executes a deposit
    // @param account the depositing account
    // @param params ExecuteDepositParams
    function executeDeposit(address account, ExecuteDepositParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.poolTokenAddress);
        Pool.PoolCache memory poolCache =  PoolUtils.cache(pool);

        IPoolToken poolToken = IPoolToken(poolCache.poolTokenAddress);
        address underlyingTokenAddress = poolToken.underlyingTokenAddress();

        //multicall 
        uint256 depositAmount = poolToken.recordTransferIn(underlyingTokenAddress);
        if(depositAmount > POOL_MINI_DEPOSIT_AMOUNT) {
            revert Errors.DidNotReachMiniDepositAmount(depositAmount, POOL_MINI_DEPOSIT_AMOUNT);
        }

        PoolUtils.updateIndexesAndIncrementFeeAmount(pool, poolCache);

        ExecuteDepositUtils.validateDeposit(pool, poolCache, depositAmountt)
        PoolUtils.updateInterestRates(pool, poolCache, underlyingTokenAddress, depositAmount, 0);

        PoolStoreUtils.set(params.dataStore, params.poolTokenAddress, PoolUtils.getPoolSalt(underlyingTokenAddress), pool);

        //IERC20(underlyingTokenAddress).safeTransferFrom(msg.sender, poolCache.poolTokenAddress, params.amount);
        IPoolToken(poolCache.poolTokenAddress).mint(params.receiver, depositAmount, poolCache.nextLiquidityIndex)
    }

    
    // @dev validates a deposit action.
    // @param pool The cached data of the pool
    // @param amount The amount to be supply
    function validateDeposit(
        PoolCache.Props memory poolCache,
        uint256 amount
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);

        (bool isActive, bool isFrozen, , bool isPaused) = poolCache.poolConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(!isFrozen, Errors.RESERVE_FROZEN);

        //uint256 unClaimedFee = FeeUtils.getUnClaimeFee(poolCache);
        uint256 supplyCapacity = PoolConfigurationUtils.getSupplyCapacity(poolCache.poolConfiguration);
        require(
          supplyCapacity == 0 ||
            ((IPoolTaken(poolCache.poolTokenAddress).scaledTotalSupply() +
              unClaimedFee.rayMul(poolCache.nextLiquidityIndex) + amount) <=
            supplyCapacity * (10 ** poolCache.poolConfiguration.getDecimals()),
          Errors.SUPPLY_CAPACITY_EXCEEDED
        );
    }    
    
}
