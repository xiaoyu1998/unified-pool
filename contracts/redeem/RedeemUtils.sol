// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../position/Position.sol";
import "../position/PositionStoreUtils.sol";
import "../position/PositionUtils.sol";

// @title RedeemUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library RedeemUtils {

    struct RedeemParams {
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    struct ExecuteRedeemParams {
        DataStore dataStore;
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    // @dev executes a deposit
    // @param account the depositng account
    // @param params ExecuteRedeemParams
    function executeRedeem(address account, ExecuteRedeemParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.underlyingAsset);
        PoolUtils.validateEnabledPool(pool);

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        RedeemUtils.validateRedeem(pool, poolCache, position, params.amount)

        IPoolToken poolToken   = IPoolToken(pool.poolToken);
        poolToken.removeCollateral(account, amount);
        if(poolToken.balanceOfCollateral(account) == 0)) {
            position.setPoolAsCollateral(pool.poolKeyId(), false)
            PositionStoreUtils.set(params.dataStore, account, position);
        }

        IERC20(params.underlyingAsset).safeTransfer(params.to, params.amount);
    }


      // /**
      //  * @notice Validates a withdraw action.
      //  * @param poolCache The cached data of the pool
      //  * @param amount The amount to be withdrawn
      //  * @param userBalance The balance of the user
      //  */
      // function validateRedeem(
      //     Position.Props memory position,
      //     PoolCache.Props memory poolCache,
      //     uint256 amount
      // ) internal pure {
      //  PositionUtils.validateEnabledPosition(position);
      // }
    
}
