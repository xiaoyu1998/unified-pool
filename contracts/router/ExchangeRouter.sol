// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../exchange/IDepositHandler.sol";
// import "../exchange/IWithdrawalHandler.sol";
// import "../exchange/IBorrowHandler.sol";

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
 * swap, increase / decrease position
 * - Keepers listen for the transactions, include the prices for the request then
 * send a transaction to execute the request
 *
 * Prices are provided by an off-chain oracle system:
 *
 * - Oracle keepers continually check the latest blocks
 * - When there is a new block, oracle keepers fetch the latest prices from
 * reference exchanges
 * - Oracle keepers then sign the median price for each token together with
 * the block hash
 * - Oracle keepers then send the data and signature to archive nodes
 * - Archive nodes display this information for anyone to query
 *
 * Example:
 *
 * - Block 100 is finalized on the blockchain
 * - Oracle keepers observe this block
 * - Oracle keepers pull the latest prices from reference exchanges,
 * token A: price 20,000, token B: price 80,000
 * - Oracle keepers sign [chainId, blockhash(100), 20,000], [chainId, blockhash(100), 80,000]
 * - If in block 100, there was a market order to open a long position for token A,
 * the market order would have a block number of 100
 * - The prices signed at block 100 can be used to execute this order
 * - Order keepers would bundle the signature and price data for token A
 * then execute the order
 */
contract ExchangeRouter is IExchangeRouter, BaseRouter {
    using Deposit for Deposit.Props;
    // using Withdrawal for Withdrawal.Props;
    // using Borrow for Borrow.Props;
    // using Repay for Repay.Props;
    // using Liquidation for Liquidation.Props;
    // using Swap for Swap.Props;

    IDepositHandler public immutable depositHandler;
    // IWithdrawalHandler public immutable withdrawalHandler;
    // IBorrowHandler public immutable borrowHandler;
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
        // IWithdrawalHandler _withdrawalHandler,
        // IBorrowHandler _borrowHandler,
        // IRepayHandler _repayHandler,
        // ILiquidationHandler _liquidationHandler,
        // ISwapHandler _swapHandler
    ) BaseRouter(_router, _roleStore, _dataStore) {
        depositHandler     = _depositHandler;
        // withdrawalHandler  = _withdrawalHandler;
        // borrowHandler      = _borrowHandler;
        // repayHandler       = _repayHandler;
        // liquidationHandler = _liquidationHandler;
        // swapHandler        = _swapHandler;
    }

    /**
     * @dev Creates a new deposit with the given long token, short token, long token amount, short token
     * amount, and deposit parameters. The deposit is created by transferring the specified amounts of
     * long and short tokens from the caller's account to the deposit store, and then calling the
     * `executeDeposit()` function on the deposit handler contract.
     *
     * @param params The deposit parameters, as specified in the `DepositUtils.ExecuteDepositParams` struct
     * @return The unique ID of the newly created deposit
     */
    function executeDeposit(
        DepositUtils.ExecuteDepositParams calldata params
    ) external override payable nonReentrant returns (bytes32) {
        address account = msg.sender;

        return depositHandler.executeDeposit(
            account,
            params
        );
    }

    /**
     * @dev Creates a new withdrawal with the given withdrawal parameters. The withdrawal is created by
     * calling the `executeWithdrawal()` function on the withdrawal handler contract.
     *
     * @param params The withdrawal parameters, as specified in the `WithdrawalUtils.ExecuteWithdrawalParams` struct
     * @return The unique ID of the newly created withdrawal
     */
    function executeWithdrawal(
        WithdrawalUtils.ExecuteWithdrawalParams calldata params
    ) external override payable nonReentrant returns (bytes32) {
        address account = msg.sender;

        return withdrawalHandler.executeWithdrawal(
            account,
            params
        );
    }

    /**
     * @dev Creates a new order with the given amount, order parameters. The order is
     * created by transferring the specified amount of collateral tokens from the caller's account to the
     * order store, and then calling the `executeBorrow()` function on the order handler contract. The
     * referral code is also set on the caller's account using the referral storage contract.
     */
    function executeBorrow(
        IBorrowUtils.ExecuteBorrowParams calldata params
    ) external override payable nonReentrant returns (bytes32) {
        address account = msg.sender;

        return borrowHandler.executeBorrow(
            account,
            params
        );
    }


}
