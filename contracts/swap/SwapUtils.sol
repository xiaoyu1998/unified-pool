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
import "../dex/DexStoreUtils.sol";
import "../dex/IDex.sol";

import "../event/EventEmitter.sol";
import "./SwapEventUtils.sol";

// @title SwapUtils
// @dev Library for swap functions, to help with the swaping of underlyinAssetIn
// into a dex pool in return for underlyinAssetOut
library SwapUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct SwapParams {
        address underlyingAssetIn;
        address underlyingAssetOut;
        uint256 amount;
        uint256 sqrtPriceLimitX96;
    }

    struct ExecuteSwapParams {
        address dataStore;
        address eventEmitter;
        address underlyingAssetIn;
        address underlyingAssetOut;
        uint256 amount;
        uint256 sqrtPriceLimitX96;
    }

    struct SwapLocalVars {
        Pool.Props poolIn;
        address poolKeyIn;
        bool poolInIsUsd;
        Pool.Props poolOut;
        address poolKeyOut;
        bool poolOutIsUsd;
        bytes32 positionKeyIn;
        Position.Props positionIn;
        Position.Props positionOut;
        bytes32 positionKeyOut;
        IPoolToken poolTokenIn;
        IPoolToken poolTokenOut;
        IDebtToken debtTokenIn;
        IDebtToken debtTokenOut;
        uint256 collateralAmount;
        address dex;
        uint256 amountInAfterSwap;
        uint256 amountOutAfterSwap;
        uint256 amountIn;
        uint256 amountOut;
        uint256 price;
        uint256 priceIn;
        uint256 priceOut;

        uint256 collateralIn;
        uint256 debtScaledIn;
        uint256 collateralOut;
        uint256 debtScaledOut;
    }

    // @dev executes a swap
    // @param account the swap account
    // @param params ExecuteSwapParams
    function executeSwapExactIn(address account, ExecuteSwapParams calldata params) external returns (uint256) {
        Printer.log("-------------------------executeSwap--------------------------");
        SwapLocalVars memory vars;
        (   vars.poolIn,
            ,
            vars.poolKeyIn,
            vars.poolInIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAssetIn);
        (   vars.poolOut,
            ,
            vars.poolKeyOut,
            vars.poolOutIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAssetOut);

        vars.positionKeyIn = Keys.accountPositionKey(params.underlyingAssetIn, account);
        vars.positionIn  = PositionStoreUtils.get(params.dataStore, vars.positionKeyIn);
        (   vars.positionOut,
            vars.positionKeyOut
        ) = PositionUtils.getOrInit(
            account,
            params.dataStore, 
            params.underlyingAssetOut, 
            Position.PositionTypeLong,
            vars.poolOutIsUsd
        );

        vars.debtTokenIn  = IDebtToken(vars.poolIn.debtToken);
        vars.debtTokenOut = IDebtToken(vars.poolOut.debtToken);
        vars.poolTokenIn  = IPoolToken(vars.poolIn.poolToken);
        vars.poolTokenOut = IPoolToken(vars.poolOut.poolToken);
        vars.amountIn = params.amount;
        vars.collateralAmount = vars.poolTokenIn.balanceOfCollateral(account);
        if( vars.amountIn > vars.collateralAmount){
            vars.amountIn = vars.collateralAmount;
        }
        
        vars.dex = DexStoreUtils.get(params.dataStore, params.underlyingAssetIn, params.underlyingAssetOut);
        SwapUtils.validateSwap( 
            vars.poolIn, 
            vars.poolOut,
            vars.amountIn,
            vars.dex
        );

        Printer.log("-------------------------swapStart--------------------------");
        //swap
        vars.poolTokenIn.approveLiquidity(vars.dex, vars.amountIn);
        IDex(vars.dex).swapExactIn(
            address(vars.poolTokenIn), 
            params.underlyingAssetIn, 
            vars.amountIn, 
            address(vars.poolTokenOut),
            params.sqrtPriceLimitX96
        );
        vars.poolTokenIn.approveLiquidity(vars.dex, 0);
        Printer.log("-------------------------swapEnd--------------------------");

        vars.amountInAfterSwap = vars.poolTokenIn.recordTransferOut(params.underlyingAssetIn);
        vars.amountOut = vars.poolTokenOut.recordTransferIn(params.underlyingAssetOut);
        if (vars.amountIn != vars.amountInAfterSwap) {
            revert Errors.InsufficientDexLiquidity(vars.amountInAfterSwap, vars.amountIn);
        }
        
        //update collateral
        vars.poolTokenIn.removeCollateral(account, vars.amountIn);//this line will assert if account InsufficientCollateralAmount
        vars.poolTokenOut.addCollateral(account, vars.amountOut);

        //update position and entryPrice
        if (vars.poolTokenIn.balanceOfCollateral(account) == 0){
            vars.positionIn.hasCollateral  = false;
        }
        vars.positionOut.hasCollateral = true;

        if (vars.poolInIsUsd || vars.poolOutIsUsd) {//swap with usd
            vars.price = OracleUtils.calcPrice(
                vars.amountIn,
                PoolConfigurationUtils.getDecimals(vars.poolIn.configuration), 
                vars.amountOut,
                PoolConfigurationUtils.getDecimals(vars.poolOut.configuration),
                vars.poolOutIsUsd
            );
            
            if (vars.poolInIsUsd && !vars.poolOutIsUsd) { //long out
                PositionUtils.longPosition(vars.positionOut, vars.price, vars.amountOut, true);
            }

            if (!vars.poolInIsUsd && vars.poolOutIsUsd) { //Short in
                PositionUtils.shortPosition(vars.positionIn,  vars.price, vars.amountIn, true);
            } 
        } else {//swap without usd
            vars.priceIn = OracleUtils.getPrice(params.dataStore, params.underlyingAssetIn);
            PositionUtils.shortPosition(vars.positionIn,  vars.priceIn, vars.amountIn, true);

            vars.priceOut = OracleUtils.getPrice(params.dataStore, params.underlyingAssetOut);
            PositionUtils.longPosition(vars.positionOut, vars.priceOut, vars.amountOut, true);
        }

        //update postions
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKeyIn, 
            vars.positionIn
        );
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKeyOut, 
            vars.positionOut
        );

        // PoolUtils.updateInterestRates(
        //     poolIn,
        //     poolCacheIn, 
        //     params.underlyingAssetIn
        // );
        PoolStoreUtils.set(
            params.dataStore, 
            vars.poolKeyIn, 
            vars.poolIn
        );

        // PoolUtils.updateInterestRates(
        //     poolOut,
        //     poolCacheOut, 
        //     params.underlyingAssetOut
        // );
        PoolStoreUtils.set(
            params.dataStore, 
            vars.poolKeyOut, 
            vars.poolOut
        );

        //vars.amountIn * IDex(vars.dex).getFeeAmount()*;

        vars.collateralIn  = vars.poolTokenIn.balanceOfCollateral(account);
        vars.debtScaledIn  = vars.debtTokenIn.scaledBalanceOf(account);
        vars.collateralOut = vars.poolTokenOut.balanceOfCollateral(account);
        vars.debtScaledOut = vars.debtTokenOut.scaledBalanceOf(account) ;

        SwapEventUtils.emitSwap(
            params.eventEmitter, 
            params.underlyingAssetIn, 
            params.underlyingAssetOut, 
            account, 
            vars.amountIn,
            vars.amountOut,
            IDex(vars.dex).getSwapFee(vars.amountIn),
            vars.collateralIn,
            vars.debtScaledIn,
            vars.collateralOut,
            vars.debtScaledOut  
        );

        //return (amountIn, amountOut);
        return vars.amountOut;

    }

    // @dev executes a swap
    // @param account the swap account
    // @param params ExecuteSwapParams
    function executeSwapExactOut(address account, ExecuteSwapParams calldata params) external returns (uint256) {
        Printer.log("-------------------------executeSwap--------------------------");
        SwapLocalVars memory vars;
        (   vars.poolIn,
            ,
            vars.poolKeyIn,
            vars.poolInIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAssetIn);
        (   vars.poolOut,
            ,
            vars.poolKeyOut,
            vars.poolOutIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAssetOut);

        vars.positionKeyIn = Keys.accountPositionKey(params.underlyingAssetIn, account);
        vars.positionIn  = PositionStoreUtils.get(params.dataStore, vars.positionKeyIn);
        (   vars.positionOut,
            vars.positionKeyOut
        ) = PositionUtils.getOrInit(
            account,
            params.dataStore, 
            params.underlyingAssetOut, 
            Position.PositionTypeLong,
            vars.poolOutIsUsd
        );

        vars.debtTokenIn  = IDebtToken(vars.poolIn.debtToken);
        vars.debtTokenOut = IDebtToken(vars.poolOut.debtToken);
        vars.poolTokenIn  = IPoolToken(vars.poolIn.poolToken);
        vars.poolTokenOut  = IPoolToken(vars.poolOut.poolToken);
        vars.amountOut = params.amount;//should be change to amount
        vars.collateralAmount = vars.poolTokenIn.balanceOfCollateral(account);
        
        vars.dex = DexStoreUtils.get(params.dataStore, params.underlyingAssetIn, params.underlyingAssetOut);
        SwapUtils.validateSwap( 
            vars.poolIn, 
            vars.poolOut,
            vars.amountOut,
            vars.dex
        );

        Printer.log("-------------------------swapStart--------------------------");
        //swap
        vars.poolTokenIn.approveLiquidity(vars.dex, vars.collateralAmount);
        IDex(vars.dex).swapExactOut(
            address(vars.poolTokenIn), 
            params.underlyingAssetIn, 
            vars.amountOut, 
            address(vars.poolTokenOut),
            params.sqrtPriceLimitX96
        );
        vars.poolTokenIn.approveLiquidity(vars.dex, 0);
        Printer.log("-------------------------swapEnd--------------------------");

        vars.amountIn = vars.poolTokenIn.recordTransferOut(params.underlyingAssetIn);
        vars.amountOutAfterSwap = vars.poolTokenOut.recordTransferIn(params.underlyingAssetOut);
        if (vars.amountOut != vars.amountOutAfterSwap) {
            revert Errors.InsufficientDexLiquidity(vars.amountOutAfterSwap, vars.amountOut);
        }
        if (vars.amountIn > vars.collateralAmount){
            revert Errors.InsufficientCollateralForSwap(vars.amountIn, vars.collateralAmount);
        }
        
        //update collateral
        vars.poolTokenIn.removeCollateral(account, vars.amountIn);//this line will assert if account InsufficientCollateralAmount
        vars.poolTokenOut.addCollateral(account, vars.amountOut);
        
        //update position and entryPrice
        if (vars.poolTokenIn.balanceOfCollateral(account) == 0){
            vars.positionIn.hasCollateral  = false;
        }
        vars.positionOut.hasCollateral = true;
        
        if (vars.poolInIsUsd || vars.poolOutIsUsd) {//swap with usd
            vars.price = OracleUtils.calcPrice(
                vars.amountIn,
                PoolConfigurationUtils.getDecimals(vars.poolIn.configuration), 
                vars.amountOut,
                PoolConfigurationUtils.getDecimals(vars.poolOut.configuration),
                vars.poolOutIsUsd
            );
            
            if (vars.poolInIsUsd && !vars.poolOutIsUsd) { //long out
                PositionUtils.longPosition(vars.positionOut, vars.price, vars.amountOut, true);
            }

            if (!vars.poolInIsUsd && vars.poolOutIsUsd) { //Short in
                PositionUtils.shortPosition(vars.positionIn,  vars.price, vars.amountIn, true);
            } 
        } else {//swap without usd
            vars.priceIn = OracleUtils.getPrice(params.dataStore, params.underlyingAssetIn);
            PositionUtils.shortPosition(vars.positionIn,  vars.priceIn, vars.amountIn, true);

            vars.priceOut = OracleUtils.getPrice(params.dataStore, params.underlyingAssetOut);
            PositionUtils.longPosition(vars.positionOut, vars.priceOut, vars.amountOut, true);
        }

        //update postions
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKeyIn, 
            vars.positionIn
        );
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKeyOut, 
            vars.positionOut
        );

        // PoolUtils.updateInterestRates(
        //     poolIn,
        //     poolCacheIn, 
        //     params.underlyingAssetIn
        // );
        PoolStoreUtils.set(
            params.dataStore, 
            vars.poolKeyIn, 
            vars.poolIn
        );

        // PoolUtils.updateInterestRates(
        //     poolOut,
        //     poolCacheOut, 
        //     params.underlyingAssetOut
        // );
        PoolStoreUtils.set(
            params.dataStore, 
            vars.poolKeyOut, 
            vars.poolOut
        );

        vars.collateralIn  = vars.poolTokenIn.balanceOfCollateral(account);
        vars.debtScaledIn  = vars.debtTokenIn.scaledBalanceOf(account);
        vars.collateralOut = vars.poolTokenOut.balanceOfCollateral(account);
        vars.debtScaledOut = vars.debtTokenOut.scaledBalanceOf(account) ;

        SwapEventUtils.emitSwap(
            params.eventEmitter, 
            params.underlyingAssetIn, 
            params.underlyingAssetOut, 
            account, 
            vars.amountIn,
            vars.amountOut,
            IDex(vars.dex).getSwapFee(vars.amountIn),
            vars.collateralIn,
            vars.debtScaledIn,
            vars.collateralOut,
            vars.debtScaledOut  
        );

        //return (amountIn, amountOut);
        return vars.amountIn;

    }


    // @notice Validates a swap action.
    // @param amountIn The amount to be swapped in
    function validateSwap(
        Pool.Props memory poolIn,
        Pool.Props memory poolOut,
        uint256 amount,
        address dex
    ) internal pure {
        Printer.log("-------------------------validateSwap--------------------------");
        if (dex == address(0)){
             revert Errors.SwapPoolsNotMatch(poolIn.underlyingAsset, poolOut.underlyingAsset);
        }

        PoolUtils.validateConfigurationPool(poolIn, false);
        PoolUtils.validateConfigurationPool(poolOut, false);

        if(amount == 0) {
            revert Errors.EmptySwapAmount();
        } 
        //TODO:healthFactor should be validated        
    }

    // function getDexPool(address dataStore, address underlyingAssetA, address underlyingAssetB) external view returns (address) {
    //     address dex = DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
    //     return IDex(dex).getPool();

    // }  
}
