// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../utils/WadRayMath.sol";
import "../chain/Chain.sol";
import "../utils/Printer.sol";
/**
 * @title MathUtils library
 * @author Aave
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library InterestUtils {
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  struct CalculateInterestRatesParams {
      uint256 totalAvailableLiquidity;
      uint256 totalDebt;
      uint256 feeFactor;
      address underlyingAsset;
      address poolToken;
  }

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   */
  function calculateInterest(
      uint256 rate,
      uint256 lastUpdateTimestamp
  ) internal view returns (uint256) {
      //solium-disable-next-line
      // Printer.log("rate" , rate);
      // Printer.log("interestPaymentPeriodInSeconds" ,(Chain.currentTimestamp() - uint256(lastUpdateTimestamp)));
      // Printer.log("SECONDS_PER_YEAR" , SECONDS_PER_YEAR);
      uint256 result = rate * (Chain.currentTimestamp() - uint256(lastUpdateTimestamp));
      unchecked {
          result = result / SECONDS_PER_YEAR;
      }

      return WadRayMath.RAY + result;
  }

}
