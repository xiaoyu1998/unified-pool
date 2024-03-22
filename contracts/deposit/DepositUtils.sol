// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../pool/IPoolToken.sol";

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";

// @title DepositUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a pool in return for pool tokens
library DepositUtils {

    struct DepositParams {
        address underlyingAsset;
        //uint256 amount;
    }

    struct ExecuteDepositParams {
        DataStore dataStore;
        address underlyingAsset;
        //uint256 amount;
    }

    // @dev executes a deposit
    // @param account the depositng account
    // @param params ExecuteDepositParams
    function executeDeposit(address account, ExecuteDepositParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, PoolUtils.getKey(params.underlyingAsset));
        PoolUtils.validateEnabledPool(pool, PoolUtils.getKey(params.underlyingAsset));
        IPoolToken poolToken   = IPoolToken(pool.poolToken);

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        if(position.account() == address(0)){
            position.setAccount(account);
        }

        uint256 amount = poolToken.recordTransferIn(params.underlyingAsset);
        poolToken.addCollateral(account, amount);

        position.setPoolAsCollateral(pool.poolKeyId(), true);
        PositionStoreUtils.set(params.dataStore, PositionUtils.getPositionKey(account), position);

    }


      //
      // @notice Validates a withdraw action.
      // @param poolCache The cached data of the pool
      // @param amount The amount to be withdrawn
      // @param userBalance The balance of the user
      //
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
