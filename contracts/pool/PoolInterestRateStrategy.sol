// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "./Pool.sol";
import "./PoolUtils.sol";
import "../utils/PercentageMath.sol";


contract PoolInterestRateStrategy is IPoolInterestRateStrategy {



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
    vars.currentBorrowRate = _baseVariableBorrowRate;
  	if(vars.totalDebt != 0){
	  vars.availableLiquidity =
		IERC20(params.underlineToken).balanceOf(params.poolToken) -
		IPoolToken(params.poolToken).totalCollateral() +
		params.liquidityIn -
		params.liquidityOut;

	  vars.availableLiquidityPlusDebt = vars.availableLiquidity + vars.totalDebt;
	  vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
	  //vars.supplyUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);  //should be back
  	}

  	if( vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO){
  	  uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(
        MAX_EXCESS_USAGE_RATIO
      );
      vars.currentBorrowRate +=
        _variableRateSlope1 +
        _variableRateSlope2.rayMul(excessBorrowUsageRatio);

  	} else {
	  vars.currentBorrowRate += _variableRateSlope1.rayMul(vars.borrowUsageRatio).rayDiv(
	    OPTIMAL_USAGE_RATIO
	  );
  	}

    //calculate Liquidity Rate
    vars.currentLiquidityRate = 0;
    if(vars.totalDebt != 0) {
      // vars.currentLiquidityRate = vars.borrowUsageRatio.rayMul(vars.supplyUsageRatio).percentMul(
      //   PercentageMath.PERCENTAGE_FACTOR - params.feeFactor
      // );
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

