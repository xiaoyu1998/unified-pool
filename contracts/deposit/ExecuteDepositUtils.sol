// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


// @title DepositUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library ExecuteDepositUtils {

    struct DepositParams {
        address poolTokenAddress;
        address asset;
        //uint256 amount;
        address receiver;
    }

    struct ExecuteDepositParams {
        DataStore dataStore;
        // EventEmitter eventEmitter;
        address poolTokenAddress;
        address asset;
        //uint256 amount;
        address receiver;

    }

    // @dev executes a deposit
    // @param params ExecuteDepositParams
    function executeDeposit(address account, ExecuteDepositParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.poolTokenAddress);
        Pool.PoolCache memory poolCache =  PoolUtils.cache(pool);

        //multicall 
        uint256 depositAmount = IPoolToken(poolCache.poolTokenAddress).recordTransferIn(params.asset);
        if(depositAmount > POOL_MINI_DEPOSIT_AMOUNT) {
            revert Errors.DidNotReachMinDepositAmount(depositAmount, POOL_MINI_DEPOSIT_AMOUNT);
        }

        PoolUtils.updateState(pool, poolCache);
        ExecuteDepositUtils.validateDeposit(poolCache, pool, depositAmountt)
        PoolUtils.updateInterestRates(pool, poolCache, params.asset, depositAmount, 0);

        PoolStoreUtils.set(params.dataStore, params.poolTokenAddress, PoolUtils.getPoolSalt(params.asset), pool);

        //IERC20(params.asset).safeTransferFrom(msg.sender, poolCache.poolTokenAddress, params.amount);
        IPoolToken(poolCache.poolTokenAddress).mint(params.receiver, depositAmount, poolCache.nextLiquidityIndex)
    }

    
}
