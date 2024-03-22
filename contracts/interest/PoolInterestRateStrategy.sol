// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../pool/Pool.sol";
import "../pool/PoolUtils.sol";
import "../utils/PercentageMath.sol";

contract PoolInterestRateStrategy is IPoolInterestRateStrategy {
    uint256 public immutable OPTIMAL_USAGE_RATIO;
    uint256 public immutable MAX_EXCESS_USAGE_RATIO;
    uint256 internal immutable _rateSlope1;
    uint256 internal immutable _rateSlope2;

    constructor(
        uint256 optimalUsageRatio,
        uint256 rateSlope1,
        uint256 rateSlope2
    ) {
        if (WadRayMath.RAY < optimalUsageRatio) {
            revert Errors.InvalidOptimalUsageRate(optimalUsageRatio);
        }

        OPTIMAL_USAGE_RATIO    = optimalUsageRatio;
        MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;

        _rateSlope1 = rateSlope1;
        _rateSlope2 = rateSlope2;
    }

     /// @inheritdoc IDefaultInterestRateStrategy
    function getRateSlope1() public view returns (uint256) {
        return _rateSlope1;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getRateSlope2() public view returns (uint256) {
        return _rateSlope2;
    }   



    struct CalcInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 totalDebt;
        uint256 currentBorrowRate;
        uint256 currentLiquidityRate;
        uint256 borrowUsageRatio;
        //uint256 supplyUsageRatio;
        uint256 availableLiquidityPlusDebt;
    }

    /// @inheritdoc IReserveInterestRateStrategy
    function calculateInterestRates(
        PoolUtils.CalculateInterestRatesParams memory params
    ) public view override returns (uint256, uint256) {
      	CalcInterestRatesLocalVars memory vars;

      	vars.totalDebt = params.totalDebt;
       
       //calculate Borrow Rate
      	if (vars.totalDebt != 0){
        	  vars.availableLiquidity = IERC20(params.underlyingAsset).balanceOf(params.poolToken) 
                - IPoolToken(params.poolToken).totalCollateral() 
                + params.liquidityIn 
                - params.liquidityOut;

        	  vars.availableLiquidityPlusTotalDebt = vars.availableLiquidity + vars.totalDebt;
        	  vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusTotalDebt);
      	}

      	if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO){
        	  uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(
                MAX_EXCESS_USAGE_RATIO
            );
            vars.currentBorrowRate  += (_rateSlope1 
                + _rateSlope2.rayMul(excessBorrowUsageRatio));
      	} else {
        	  vars.currentBorrowRate += _RateSlope1
                .rayMul(vars.borrowUsageRatio)
                .rayDiv(OPTIMAL_USAGE_RATIO);
      	}

        //calculate Liquidity Rate
        if (vars.totalDebt != 0) {
            vars.currentLiquidityRate = vars.borrowUsageRatio.percentMul(
                PercentageMath.PERCENTAGE_FACTOR - params.feeFactor
            );	
        }
        
        return (
            vars.currentLiquidityRate,
            vars.currentBorrowRate,
        );   

    }

}

