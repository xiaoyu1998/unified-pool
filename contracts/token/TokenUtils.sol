// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/ErrorUtils.sol";
import "../utils/AccountUtils.sol";

import "./IWNT.sol";
 // @title TokenUtils 
 // @dev Library for token functions, helps with transferring of tokens and native token functions
library TokenUtils {
    using Address for address;
    using SafeERC20 for IERC20;

    event TokenTransferReverted(string reason, bytes returndata);
    event NativeTokenTransferReverted(string reason);

   
    // @dev Returns the address of the WNT token.
    // @param dataStore DataStore contract instance where the address of the WNT token is stored.
    // @return The address of the WNT token.
    function wnt(DataStore dataStore) internal view returns (address) {
        return dataStore.getAddress(Keys.WNT);
    }

   
   // @param token The address of the ERC20 token that is being transferred.
    // @param receiver The address of the recipient of the `token` transfer.
    // @param amount The amount of `token` to transfer.
    function transfer(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) { return; }
        AccountUtils.validateReceiver(receiver);


        (bool success0, bytes memory returndata) = nonRevertingTransferWithGasLimit(
            IERC20(token),
            receiver,
            amount
        );

        if (success0) { return; }

        (string memory reason, ) = ErrorUtils.getRevertMessage(returndata);
        emit TokenTransferReverted(reason, returndata);

        // throw custom errors to prevent spoofing of errors
        // this is necessary because contracts like DepositHandler, WithdrawalHandler, OrderHandler
        // do not cancel requests for specific errors
        revert Errors.TokenTransferError(token, receiver, amount);
    }
   
    // @dev Transfers the specified amount of ERC20 token to the specified receiver
    // address, with a gas limit to prevent the transfer from consuming all available gas.
    // adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
   
    // @param token the ERC20 contract to transfer the tokens from
    // @param to the address of the recipient of the token transfer
    // @param amount the amount of tokens to transfer
    // @param gasLimit the maximum amount of gas that the token transfer can consume
    // @return a tuple containing a boolean indicating the success or failure of the
    // token transfer, and a bytes value containing the return data from the token transfer
    function nonRevertingTransferWithGasLimit(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (bool, bytes memory) {
        bytes memory data = abi.encodeWithSelector(token.transfer.selector, to, amount);
        (bool success, bytes memory returndata) = address(token).call(data);

        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (!address(token).isContract()) {
                    return (false, "Call to non-contract");
                }
            }

            // some tokens do not revert on a failed transfer, they will return a boolean instead
            // validate that the returned boolean is true, otherwise indicate that the token transfer failed
            if (returndata.length > 0 && !abi.decode(returndata, (bool))) {
                return (false, returndata);
            }

            // transfers on some tokens do not return a boolean value, they will just revert if a transfer fails
            // for these tokens, if success is true then the transfer should have completed
            return (true, returndata);
        }

        return (false, returndata);
    }
}
