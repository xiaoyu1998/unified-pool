// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../repay/RepayUtils.sol";
import "../repay/RepaySubstituteUtils.sol";

interface IRepayHandler {
    function executeRepay(address account, RepayUtils.RepayParams calldata params) external;
    function executeRepaySubstitute(address account, RepaySubstituteUtils.RepaySubstituteParams calldata params) external;
}
