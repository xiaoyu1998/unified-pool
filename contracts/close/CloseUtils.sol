// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";
import "../oracle/OracleUtils.sol";
import "../utils/WadRayMath.sol";

import "../repay/RepayUtils.sol";
import "../swap/SwapUtils.sol";

import "../event/EventEmitter.sol";
// import "./CloseEventUtils.sol";

// @title CloseUtils
// @dev Library for close position functions, to help with the close of position
// into a market in return for market tokens
library CloseUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct ClosePositionParams {
        address underlyingAsset;
        address underlyingAssetUsd;
    }

    struct ExecuteClosePositionParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        address underlyingAssetUsd;
    }

    // @dev executes a position close
    // @param account the closing account
    // @param params ExecuteClosePositionParams
    function executeClosePosition(
        address account, 
        ExecuteClosePositionParams calldata params
    ) external {
        Printer.log("-------------------------executeClosePosition--------------------------");
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);

        bytes32 positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        Position.Props memory position = PositionStoreUtils.get(params.dataStore, positionKey);
        PositionUtils.validateEnabledPosition(position);

        IPoolToken poolToken = IPoolToken(pool.poolToken);
        IDebtToken debtToken = IDebtToken(pool.debtToken);

        uint256 collateralAmount = poolToken.balanceOfCollateral(account);
        uint256 debtAmount = debtToken.balanceOf(account);

        CloseUtils.validateClosePosition( 
            account, 
            params.dataStore, 
            pool,
            position,
            collateralAmount,
            debtAmount
        );
        if (debtAmount > 0) {
            RepayUtils.ExecuteRepayParams memory repayParams = RepayUtils.ExecuteRepayParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                debtAmount
            );
            RepayUtils.executeRepay(account, repayParams);
        }

        uint256 remainAmount = collateralAmount - debtAmount;
        // uint256 remainAmountUsd = remainAmount;
        if(remainAmount > 0 && params.underlyingAsset != params.underlyingAssetUsd) {
            address dex = DexStoreUtils.get(params.dataStore, params.underlyingAsset, params.underlyingAssetUsd);
            uint256 sqrtPriceLimitX96 = IDex(dex).getSqrtPriceLimitX96(params.underlyingAsset); 
            SwapUtils.ExecuteSwapParams memory swapParams = SwapUtils.ExecuteSwapParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                params.underlyingAssetUsd,
                remainAmount,
                sqrtPriceLimitX96
            );

            SwapUtils.executeSwap(account, swapParams);
        }

        PositionUtils.reset(position);
        PositionStoreUtils.set(params.dataStore, positionKey, position);      

        // ClosePositionEventUtils.emitClosePosition(
        //     params.eventEmitter, 
        //     params.underlyingAsset, 
        //     params.underlyingAssetUsd,
        //     account, 
        //     collateralAmount, 
        //     debtAmount,
        //     remainAmountUsd
        // );
    }

    // @notice Validates a close position action.
    // @param poolCache The cached data of the pool
    // @param collateralAmount The amount of collateral
    // @param debtAmount The amount of debt
    function validateClosePosition(
        address account,
        address dataStore,
        Pool.Props memory pool,
        Position.Props memory position,
        uint256 collateralAmount,
        uint256 debtAmount
    ) internal view {
        Printer.log("-------------------------validateClosePosition--------------------------");
        (   bool isActive,
            bool isFrozen, 
            ,
            bool isPaused
        ) = pool.configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(pool.underlyingAsset); }  
        if (isPaused)  { revert Errors.PoolIsPaused(pool.underlyingAsset);   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen(pool.underlyingAsset);   }  

        PositionUtils.validateEnabledPosition(position);

        if (collateralAmount <  debtAmount) {
            revert Errors.CollateralCanNotCoverDebt(collateralAmount, debtAmount);
        }

    }
}