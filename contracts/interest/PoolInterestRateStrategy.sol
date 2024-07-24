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
    uint256 internal immutable _rateBase;
    constructor(
        uint256 optimalUsageRatio,
        uint256 rateBase,
        uint256 rateSlope1,
        uint256 rateSlope2
    ) {
        if (WadRayMath.RAY < optimalUsageRatio) {
            revert Errors.InvalidOptimalUsageRate(optimalUsageRatio);
        }

        OPTIMAL_USAGE_RATIO    = optimalUsageRatio;
        MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;

        _rateBase = rateBase;
        _rateSlope1 = rateSlope1;
        _rateSlope2 = rateSlope2;
    }

    /// @inheritdoc IPoolInterestRateStrategy
    function getRatebase() public view  override returns (uint256) {
        return _rateBase;
    }
    
    /// @inheritdoc IPoolInterestRateStrategy
    function getOptimalUsageRatio() public view  override returns (uint256) {
        return OPTIMAL_USAGE_RATIO;
    }

    /// @inheritdoc IPoolInterestRateStrategy
    function getRateSlope1() public view  override returns (uint256) {
        return _rateSlope1;
    }
    
    /// @inheritdoc IPoolInterestRateStrategy
    function getRateSlope2() public view  override returns (uint256) {
        return _rateSlope2;
    }   

    struct CalcInterestRatesLocalVars {
        uint256 totalAvailableLiquidity;
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

      	CalcInterestRatesLocalVars memory vars;
      	vars.totalDebt = params.totalDebt;
        vars.currentBorrowRate = _rateBase;
       
       //calculate Borrow Rate
      	if (vars.totalDebt != 0){
              vars.totalAvailableLiquidity = params.totalAvailableLiquidity;
        	  vars.availableLiquidityAddTotalDebt = vars.totalAvailableLiquidity + vars.totalDebt;
        	  vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityAddTotalDebt);
      	}

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

