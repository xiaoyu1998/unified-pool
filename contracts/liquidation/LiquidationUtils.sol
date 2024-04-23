// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";
import "../utils/WadRayMath.sol";
import "../event/EventEmitter.sol";
import "./LiquidationEventUtils.sol";

// @title LiquidationUtils
library LiquidationUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;
    using SafeERC20 for IERC20;

    struct LiquidationParams {
        address account;
    }

    struct ExecuteLiquidationParams {
        address dataStore;
        address eventEmitter;
        address account;
    }

    // @dev executes a liquidation
    // @param params ExecuteLiquidationParams
    function executeLiquidation(address liquidator, ExecuteLiquidationParams calldata params) external {
        Printer.log("-------------------------executeLiquidation--------------------------");
        (   uint256 healthFactor,
            uint256 healthFactorLiquidationThreshold
        ) = LiquidationUtils.validateLiquidation(
            params.account, 
            params.dataStore
        );

        LiquidationEventUtils.emitHealthFactorLowerThanLiquidationThreshold(
            params.eventEmitter, 
            params.account,
            healthFactor, 
            healthFactorLiquidationThreshold
        );

        uint256 positionCount = PositionStoreUtils.getAccountPositionCount(params.dataStore, params.account);
        bytes32[] memory positionKeys = 
            PositionStoreUtils.getAccountPositionKeys(params.dataStore, params.account, 0, positionCount);

        for (uint256 i; i < positionKeys.length; i++) {
            bytes32 positionKey = positionKeys[i];
            Position.Props memory position = PositionStoreUtils.get(params.dataStore, positionKey);

            // address poolKey = Keys.poolKey(position.underlyingAsset);
            // Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
            // PoolUtils.validateEnabledPool(pool, poolKey);
            // PoolCache.Props memory poolCache = PoolUtils.cache(pool);
            // PoolUtils.updateStateBetweenTransactions(pool, poolCache);
            (
                Pool.Props memory pool,
                PoolCache.Props memory poolCache 
            ) = PoolUtils.updatePoolAndCache(params.dataStore, position.underlyingAsset);

            LiquidationUtils.validatePool(position.underlyingAsset, pool.configuration);

            IPoolToken poolToken = IPoolToken(pool.poolToken);
            uint256 collateralAmount;
            uint256 debtAmount;
            if (position.hasCollateral){
                collateralAmount = poolToken.balanceOfCollateral(position.account);
                poolToken.removeCollateral(position.account, collateralAmount);
                poolToken.transferOutUnderlyingAsset(liquidator, collateralAmount);
            }

            if (position.hasDebt){
                IDebtToken debtToken = IDebtToken(pool.debtToken);
                debtAmount = debtToken.balanceOf(position.account);
                debtToken.burnAll(position.account);

                //TODO:should be move to Router
                IERC20(position.underlyingAsset).safeTransferFrom(liquidator, address(poolToken), debtAmount);
                poolToken.syncUnderlyingAssetBalance();             
            }

            PositionUtils.reset(position);
            PositionStoreUtils.set(params.dataStore, positionKey, position);

            PoolUtils.updateInterestRates(
                pool,
                poolCache, 
                position.underlyingAsset, 
                0, 
                0
            );

            PoolStoreUtils.set(
                params.dataStore, 
                position.underlyingAsset, 
                pool
            );

            LiquidationEventUtils.emitLiquidation(
                params.eventEmitter, 
                position.underlyingAsset, 
                params.account, 
                collateralAmount,
                debtAmount,
                OracleUtils.getPrice(params.dataStore, position.underlyingAsset)
            );
        }
    }

    //
    // @notice Validates a liquidation action.
    //
    function validateLiquidation(
        address account,
        address dataStore
    ) internal view returns(uint256, uint256) {
        (   uint256 healthFactor,
            uint256 healthFactorLiquidationThreshold,
            bool isHealtherFactorHigherThanLiquidationThreshold
        ) = PositionUtils.getLiquidationHealthFactor(account, dataStore);

        if (isHealtherFactorHigherThanLiquidationThreshold) {
            revert Errors.HealthFactorHigherThanLiquidationThreshold(
                healthFactor, 
                healthFactorLiquidationThreshold
            );
        }

        return (healthFactor, healthFactorLiquidationThreshold);
    }

    function validatePool(
        address underlyingAsset,
        uint256 configuration
    ) internal pure {
        (   bool isActive,
            bool isFrozen, 
            ,
            bool isPaused
        ) = configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(underlyingAsset); }  
        if (isPaused)  { revert Errors.PoolIsPaused(underlyingAsset);   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen(underlyingAsset);   }  
    }
    
}
