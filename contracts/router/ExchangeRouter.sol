// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../exchange/IDepositHandler.sol";
import "../exchange/IWithdrawalHandler.sol";
import "../exchange/IBorrowHandler.sol";

import "../deposit/IWithdrawalHandler.sol";
import "../exchange/IBorrowHandler.sol";

import "./BaseRouter.sol";
import "./IExchangeRouter.sol";

/**
 * @title ExchangeRouter
 * @dev Router for exchange functions, supports functions which require
 * token transfers from the user
 *
 * IMPORTANT: PayableMulticall uses delegatecall, msg.value will be the same for each delegatecall
 * extra care should be taken when using msg.value in any of the functions in this contract
 *
 * To avoid front-running issues, most actions require two steps to execute:
 *
 * - User sends transaction with request details, e.g. deposit / withdraw liquidity,
 * borrow, repay, swap,
 *
 * Example:
 *
 */
contract ExchangeRouter is IExchangeRouter, BaseRouter {
    //using Deposit for Deposit.Props;
    // using Withdrawal for Withdrawal.Props;
    // using Borrow for Borrow.Props;
    // using Repay for Repay.Props;
    // using Liquidation for Liquidation.Props;
    // using Swap for Swap.Props;

    IDepositHandler public immutable depositHandler;
    IWithdrawalHandler public immutable withdrawalHandler;
    IBorrowHandler public immutable borrowHandler;
    // IRepayHandler public immutable repayHandler;
    // ILiquidationHandler public immutable liquidationHandler;
    // ISwapHandler public immutable swapHandler;

    // @dev Constructor that initializes the contract with the provided Router, RoleStore, DataStore,
    // EventEmitter, IDepositHandler, IWithdrawalHandler, IOrderHandler, and OrderStore instances
    constructor(
        Router _router,
        RoleStore _roleStore,
        DataStore _dataStore,
        IDepositHandler _depositHandler,
        IWithdrawalHandler _withdrawalHandler,
        IBorrowHandler _borrowHandler,
        // IRepayHandler _repayHandler,
        // ILiquidationHandler _liquidationHandler,
        // ISwapHandler _swapHandler
    ) BaseRouter(_router, _roleStore, _dataStore) {
        depositHandler     = _depositHandler;
        withdrawalHandler  = _withdrawalHandler;
        borrowHandler      = _borrowHandler;
        // repayHandler       = _repayHandler;
        // liquidationHandler = _liquidationHandler;
        // swapHandler        = _swapHandler;
    }

    /**
     * @dev The deposit is executed by transferring the specified amounts of tokens from the caller's 
     * account to the pool, and then calling the executeDeposit()` function on the deposit 
     * handler contract.
     *
     * @param params The deposit parameters, as specified in the `DepositUtils.ExecuteDepositParams` struct
     */
    function executeDeposit(
        DepositUtils.DepositParams calldata params
    ) external override payable nonReentrant returns (bytes32) {
        address account = msg.sender;

        return depositHandler.executeDeposit(
            account,
            params
        );
    }

    /**
     * @dev The withrawal is executed by transferring the specified amounts of pool tokens from the caller's 
     * account to the pool, and execute a  withdrawal with the given withdrawal parameters. 
     * The withdrawal is execute by calling the `executeWithdrawal()` function on the withdrawal 
     * handler contract.
     *
     * @param params The withdrawal parameters, as specified in the `WithdrawalUtils.ExecuteWithdrawalParams` struct
     */
    function executeWithdrawal(
        WithdrawalUtils.WithdrawalParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return withdrawalHandler.executeWithdrawal(
            account,
            params
        );
    }

    /**
     * @dev execute a new Borrow with the given amount, Borrow parameters. The Borrow is
     * execute by calling the `executeBorrow()` function on the Borrow handler contract. 
     */
    function executeBorrow(
        BorrowUtils.ExecuteBorrowParams calldata params
    ) external override payable nonReentrant  {
        address account = msg.sender;

        return borrowHandler.executeBorrow(
            account,
            params
        );
    }


}
