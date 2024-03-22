// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../exchange/ISupplyHandler.sol";
import "../exchange/IWithdrawHandler.sol";
import "../exchange/IDepositHandler.sol";
import "../exchange/IBorrowHandler.sol";
import "../exchange/IRepayHandler.sol";
import "../exchange/IRedeemHandler.sol";

interface IExchangeRouter {
    function executeSupply(
        SupplyUtils.SupplyParams calldata params
    ) external payable returns (bytes32);

    function executeWithdraw(
        WithdrawUtils.WithdrawParams calldata params
    ) external payable returns (bytes32);

    function executeDeposit(
        DepositUtils.DepositParams calldata params
    ) external payable returns (bytes32);

    function executeBorrow(
        BorrowUtils.ExecuteBorrowParams calldata params
    ) external payable returns (bytes32);

    function executeRepay(
        RepayUtils.ExecuteRepayParams calldata params
    ) external payable returns (bytes32);

    function executeRedeem(
        RedeemUtils.ExecuteRedeemParams calldata params
    ) external payable returns (bytes32);
}
