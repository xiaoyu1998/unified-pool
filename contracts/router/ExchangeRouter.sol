// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../exchange/ISupplyHandler.sol";
import "../exchange/IWithdrawHandler.sol";
import "../exchange/IDepositHandler.sol";
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
    ISupplyHandler public immutable supplyHandler;
    IWithdrawHandler public immutable withdrawHandler;
    IDepositHandler public immutable depositHandler;
    IBorrowHandler public immutable borrowHandler;
    IRepayHandler public immutable repayHandler;
    IRedeemHandler public immutable redeemHandler;
    // ILiquidationHandler public immutable liquidationHandler;
    // ISwapHandler public immutable swapHandler;

    // @dev Constructor that initializes the contract with the provided Router, RoleStore, DataStore,
    // EventEmitter, IDepositHandler, IWithdrawHandler, IOrderHandler, and OrderStore instances
    constructor(
        Router _router,
        RoleStore _roleStore,
        DataStore _dataStore,
        ISupplyHandler _supplyHandler,
        IWithdrawHandler _withdrawHandler, 
        IDepositHandler _depositHandler,
        IBorrowHandler _borrowHandler,
        IRepayHandler _repayHandler,
        IRedeemHandler _redeemHandler
        // ILiquidationHandler _liquidationHandler,
        // ISwapHandler _swapHandler
    ) BaseRouter(_router, _roleStore, _dataStore) {
        supplyHandler      = _supplyHandler;
        withdrawHandler    = _withdrawHandler;
        depositHandler     = _depositHandler;
        borrowHandler      = _borrowHandler;
        repayHandler       = _repayHandler;
        redeemHandler      = _redeemHandler;
        // liquidationHandler = _liquidationHandler;
        // swapHandler        = _swapHandler;
    }

    /**
     * @dev The Supply is executed by transferring the specified amounts of tokens from the caller's 
     * account to the pool, and then calling the executeSupply()` function on the Supply 
     * handler contract.
     *
     * @param params The Supply parameters, as specified in the `SupplyUtils.ExecuteSupplyParams` struct
     */
    function executeSupply(
        SupplyUtils.SupplyParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return supplyHandler.executeSupply(
            account,
            params
        );
    }

    /**
     * @dev The withdraw is executed by transferring the specified amounts of pool tokens from the caller's 
     * account to the pool, and execute a  withdraw with the given withdraw parameters. 
     * The withdraw is execute by calling the `executeWithdrawal()` function on the withdraw 
     * handler contract.
     *
     * @param params The withdraw parameters, as specified in the `WithdrawalUtils.ExecuteWithdrawalParams` struct
     */
    function executeWithdraw(
        WithdrawUtils.WithdrawParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return withdrawHandler.executeWithdraw(
            account,
            params
        );
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
    ) external override payable nonReentrant {
        address account = msg.sender;

        return depositHandler.executeDeposit(
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
    ) external override payable nonReentrant {
        address account = msg.sender;

        return borrowHandler.executeBorrow(
            account,
            params
        );
    }

    /**
     * @dev execute a new Repay with the given amount, Repay parameters. The Repay is
     * execute by calling the `executeRepay()` function on the Repay handler contract. 
     */
    function executeRepay(
        RepayUtils.ExecuteRepayParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return repayHandler.executeRepay(
            account,
            params
        );
    }

    /**
     * @dev execute a new Redeem with the given amount, Redeem parameters. The Redeem is
     * execute by calling the `executeRedeem()` function on the Redeem handler contract. 
     */
    function executeRedeem(
        RedeemUtils.ExecuteRedeemParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return redeemHandler.executeRedeem(
            account,
            params
        );
    }


}
