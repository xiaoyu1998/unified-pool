// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../error/Errors.sol";
import "../token/IPoolToken.sol";
import "../utils/PercentageMath.sol";
import "../utils/WadRayMath.sol";

import "./IPoolInterestRateStrategy.sol";
import "../utils/Printer.sol";

contract PoolInterestRateStrategy is IPoolInterestRateStrategy {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

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

     
    function getRateSlope1() public view returns (uint256) {
        return _rateSlope1;
    }

    function getRateSlope2() public view returns (uint256) {
        return _rateSlope2;
    }   


    struct CalcInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 totalDebt;
        uint256 currentBorrowRate;
        uint256 currentLiquidityRate;
        uint256 borrowUsageRatio;
        uint256 availableLiquidityAddTotalDebt;
    }

    /// @inheritdoc IPoolInterestRateStrategy
    function calculateInterestRates(
        InterestUtils.CalculateInterestRatesParams memory params
    ) public view override returns (uint256, uint256) {
        Printer.log("--------------------calculateInterestRates---------------------");
        Printer.log("optimalUsageRatio", OPTIMAL_USAGE_RATIO);
        Printer.log("MAX_EXCESS_USAGE_RATIO", MAX_EXCESS_USAGE_RATIO);
        Printer.log("rateSlope1", _rateSlope1);
        Printer.log("rateSlope2", _rateSlope2);

      	CalcInterestRatesLocalVars memory vars;

      	vars.totalDebt = params.totalDebt;
        Printer.log("totalDebt", vars.totalDebt);
       
       //calculate Borrow Rate
      	if (vars.totalDebt != 0){
        	  vars.availableLiquidity = IERC20(params.underlyingAsset).balanceOf(params.poolToken) 
                - IPoolToken(params.poolToken).totalCollateral() 
                + params.liquidityIn 
                - params.liquidityOut;
              Printer.log("availableLiquidity", vars.availableLiquidity);
        	  vars.availableLiquidityAddTotalDebt = vars.availableLiquidity + vars.totalDebt;
              Printer.log("availableLiquidityAddTotalDebt", vars.availableLiquidityAddTotalDebt);
        	  vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityAddTotalDebt);
      	}

        Printer.log("borrowUsageRatio", vars.borrowUsageRatio);

      	if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO){
            uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(
                MAX_EXCESS_USAGE_RATIO
            );
            vars.currentBorrowRate  += (_rateSlope1 + _rateSlope2.rayMul(excessBorrowUsageRatio));
      	} else {
        	  vars.currentBorrowRate += _rateSlope1
                  .rayMul(vars.borrowUsageRatio)
                  .rayDiv(OPTIMAL_USAGE_RATIO);
      	}

        // Printer.log("currentBorrowRate", vars.currentBorrowRate);

        //calculate Liquidity Rate
        if (vars.totalDebt != 0) {
            vars.currentLiquidityRate = vars.currentBorrowRate.rayMul(vars.borrowUsageRatio).percentMul(
                PercentageMath.PERCENTAGE_FACTOR - params.feeFactor
            );	
        }
        
        return (
            vars.currentLiquidityRate,
            vars.currentBorrowRate
        );   

    }

}

