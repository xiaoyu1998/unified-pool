// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../exchange/ISupplyHandler.sol";
import "../exchange/IWithdrawHandler.sol";
import "../exchange/IDepositHandler.sol";
import "../exchange/IBorrowHandler.sol";
import "../exchange/IRepayHandler.sol";
import "../exchange/IRedeemHandler.sol";
import "../exchange/ISwapHandler.sol";
import "../exchange/ILiquidationHandler.sol";
import "../exchange/ICloseHandler.sol";

interface IExchangeRouter {
    function executeSupply(
        SupplyUtils.SupplyParams calldata params
    ) external payable;

    function executeWithdraw(
        WithdrawUtils.WithdrawParams calldata params
    ) external payable;

    function executeDeposit(
        DepositUtils.DepositParams calldata params
    ) external payable;

    function executeBorrow(
        BorrowUtils.BorrowParams calldata params
    ) external payable;

    function executeRepay(
        RepayUtils.RepayParams calldata params
    ) external payable;

    function executeRedeem(
        RedeemUtils.RedeemParams calldata params
    ) external payable;

    function executeSwap(
        SwapUtils.SwapParams calldata params
    ) external payable;

    function executeLiquidation(
        LiquidationUtils.LiquidationParams calldata params
    ) external payable;

    function executeClosePosition(
        CloseUtils.ClosePositionParams calldata params
    ) external payable;
}
