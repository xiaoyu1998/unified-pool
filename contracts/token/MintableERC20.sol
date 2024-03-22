// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import "./IndexERC20.sol";
// @title MintableERC20 
// @author Aave
// @notice Implements mint and burn functions for IndexERC20/
abstract contract MintableERC20 is IndexERC20 {

 // @dev Constructor.
 // @param pool The reference to the main Pool contract
 // @param name The name of the token
 // @param symbol The symbol of the token
 // @param decimals The number of decimals of the token
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) IndexERC20(name, symbol, decimals) {
    // Intentionally left blank
  }


 // @notice Mints tokens to an account and apply incentives if defined
 // @param account The address receiving tokens
 // @param amount The amount of tokens to mint
  function _mint(address account, uint256 amount) internal virtual {
      require(account != address(0), "MintableERC20: mint to the zero address");
      _totalSupply += amount;
      unchecked {
          // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
          _balances[account] += amount;
      }
  }


 // @notice Burns tokens from an account and apply incentives if defined
 // @param account The account whose tokens are burnt
 // @param amount The amount of tokens to burn
  function _burn(address account, uint256 amount) internal virtual {
      require(account != address(0), "MintableERC20: burn from the zero address");

      uint256 accountBalance = _balances[account];
      require(accountBalance >= amount, "MintableERC20: burn amount exceeds balance");
      unchecked {
          _balances[account] = accountBalance - amount;
          // Overflow not possible: amount <= accountBalance <= totalSupply.
          _totalSupply -= amount;
      }
  }
}
