// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../redeem/RedeemUtils.sol";

interface IRedeemHandler {
    function executeRedeem(address account, RedeemUtils.RedeemParams calldata params) external;
}
