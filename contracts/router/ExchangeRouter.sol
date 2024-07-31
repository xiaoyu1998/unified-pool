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

import "./BaseRouter.sol";
import "./IExchangeRouter.sol";

/**
 * @title ExchangeRouter
 * @dev Router for exchange functions, supports functions which require
 * token transfers from the user
 *
 * Example:
 *
 */
contract ExchangeRouter is IExchangeRouter, BaseRouter {
    ISupplyHandler public immutable supplyHandler;
    IWithdrawHandler public immutable withdrawHandler;
    IDepositHandler public immutable depositHandler;
    IBorrowHandler public immutable borrowHandler;
    IRepayHandler public immutable repayHandler;
    IRedeemHandler public immutable redeemHandler;
    ISwapHandler public immutable swapHandler;
    ILiquidationHandler public immutable liquidationHandler;
    ICloseHandler public immutable closeHandler;

    // @dev Constructor that initializes the contract with the provided Router, RoleStore, DataStore,
    // ISupplyHandler, IWithdrawHandler, IDepositHandler, IBorrowHandler, IRepayHandler, IRedeemHandler,
    // ISwapHandler, ILiquidationHandler and ICloseHandler instances
    constructor(
        Router _router,
        RoleStore _roleStore,
        DataStore _dataStore,
        ISupplyHandler _supplyHandler,
        IWithdrawHandler _withdrawHandler, 
        IDepositHandler _depositHandler,
        IBorrowHandler _borrowHandler,
        IRepayHandler _repayHandler,
        IRedeemHandler _redeemHandler,
        ISwapHandler _swapHandler,
        ILiquidationHandler _liquidationHandler,
        ICloseHandler _closeHandler
    ) BaseRouter(_router, _roleStore, _dataStore) {
        supplyHandler      = _supplyHandler;
        withdrawHandler    = _withdrawHandler;
        depositHandler     = _depositHandler;
        borrowHandler      = _borrowHandler;
        repayHandler       = _repayHandler;
        redeemHandler      = _redeemHandler;
        swapHandler        = _swapHandler;
        liquidationHandler = _liquidationHandler;
        closeHandler = _closeHandler;
    }

    /**
     * @dev The Supply is executed by transferring the specified amounts of tokens from the caller's 
     * account to the pool, and then calling the executeSupply()` function on the Supply 
     * handler contract.
     *
     * @param params The Supply parameters, as specified in the `SupplyUtils.SupplyParams` struct
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
     * @dev execute a new withdraw with the given withdraw parameters. 
     * The withdraw is execute by calling the `executeWithdrawal()` function on the withdraw 
     * handler contract.
     *
     * @param params The withdraw parameters, as specified in the `WithdrawalUtils.WithdrawalParams` struct
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
     * @param params The deposit parameters, as specified in the `DepositUtils.DepositParams` struct
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
     * @dev execute a new Borrow with the given Borrow parameters. The Borrow is
     * execute by calling the `executeBorrow()` function on the Borrow handler contract. 
     */
    function executeBorrow(
        BorrowUtils.BorrowParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return borrowHandler.executeBorrow(
            account,
            params
        );
    }

    /**
     * @dev execute a new Repay with the given Repay parameters. The Repay is
     * execute by calling the `executeRepay()` function on the Repay handler contract. 
     */
    function executeRepay(
        RepayUtils.RepayParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return repayHandler.executeRepay(
            account,
            params
        );
    }

    /**
     * @dev execute a new Redeem with the given Redeem parameters. The Redeem is
     * execute by calling the `executeRedeem()` function on the Redeem handler contract. 
     */
    function executeRedeem(
        RedeemUtils.RedeemParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return redeemHandler.executeRedeem(
            account,
            params
        );
    }

    /**
     * @dev execute a new Swap with the given Swap parameters. The Swap is
     * execute by calling the `executeSwap()` function on the Swap handler contract. 
     */
    function executeSwap(
        SwapUtils.SwapParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return swapHandler.executeSwap(
            account,
            params
        );
    }

    /**
     * @dev execute a new Swap with the given Swap parameters. The Swap is
     * execute by calling the `executeSwap()` function on the Swap handler contract. 
     */
    function executeSwapExactOut(
        SwapUtils.SwapParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return swapHandler.executeSwapExactOut(
            account,
            params
        );
    }

    /**
     * @dev execute a new Liquidation with the given Liquidation parameters. The Liquidation is
     * execute by calling the `executeLiquidation()` function on the Liquidation handler contract. 
     */
    function executeLiquidation(
        LiquidationUtils.LiquidationParams calldata params
    ) external override payable nonReentrant {
        address liquidator = msg.sender;

        return liquidationHandler.executeLiquidation(
            liquidator,
            params
        );
    }

    /**
     * @dev execute a new ClosePosition with the given ClosePosition parameters. The ClosePosition is
     * execute by calling the `executeClosePosition()` function on the ClosePosition handler contract. 
     */
    function executeClosePosition(
        CloseUtils.ClosePositionParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return closeHandler.executeClosePosition(
            account,
            params
        );
    }

    /**
     * @dev execute a new Close with the given Close parameters. The Close is
     * execute by calling the `executeClose()` function on the Close handler contract. 
     */
    function executeClose(
        CloseUtils.CloseParams calldata params
    ) external override payable nonReentrant {
        address account = msg.sender;

        return closeHandler.executeClose(
            account,
            params
        );
    }


}
