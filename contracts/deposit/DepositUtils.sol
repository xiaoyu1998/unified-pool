// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "../position/Position.sol";
import "../position/PositionStoreUtils.sol";
import "../position/PositionUtils.sol";

// @title DepositUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library DepositUtils {

    struct DepositParams {
        address poolTokenAddress;
        //uint256 amount;
    }

    struct ExecuteDepositParams {
        DataStore dataStore;
        address poolTokenAddress;
        //uint256 amount;
    }

    // @dev executes a borrow
    // @param account the withdrawing account
    // @param params ExecuteDepositParams
    function executeDeposit(address account, ExecuteDepositParams calldata params) external {

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        if(position.account() == address(0)){
            positon.setAccount(account);
        }

        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.poolTokenAddress);
        PoolUtils.validateEnabledPool(pool);
        IPoolToken poolToken = IPoolToken(pool.poolTokenAddress);
        if(address(poolToken) = address(0)) {revert Errors}

        address underlyingTokenAddress = poolToken.underlyingTokenAddress();
        uint256 amount = poolToken.recordTransferIn(underlyingTokenAddress);
        if(amount <= 0)} {revert Errors}
        poolToken.addCollateral(account, amount);

        position.setAsCollateral(pool.poolKeyId. true)
        PositionStoreUtils.set(params.dataStore, PositionUtils.getPositionKey(account), positon)

    }


      // /**
      //  * @notice Validates a withdraw action.
      //  * @param poolCache The cached data of the pool
      //  * @param amount The amount to be withdrawn
      //  * @param userBalance The balance of the user
      //  */
      // function validateDeposit(
      //     Position.Props memory position,
      //     PoolCache.Props memory poolCache,
      //     uint256 amount
      // ) internal pure {
       
      //  (
      //   vars.userCollateralInBaseCurrency,
      //   vars.userDebtInBaseCurrency,
      //   var.healthFactor,
      //  ) = calculateUser()
      // }
    
}
