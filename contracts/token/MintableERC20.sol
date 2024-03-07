// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MintableIncentivizedERC20
 * @author Aave
 * @notice Implements mint and burn functions for IncentivizedERC20
 */
abstract contract MintableERC20 is ERC20 {
  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param decimals The number of decimals of the token
   */
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20(name, symbol, decimals) {
    // Intentionally left blank
  }

  /**
   * @notice Mints tokens to an account and apply incentives if defined
   * @param account The address receiving tokens
   * @param amount The amount of tokens to mint
   */
  function _mint(address account, uint128 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply + amount;

    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance + amount;

  }

  /**
   * @notice Burns tokens from an account and apply incentives if defined
   * @param account The account whose tokens are burnt
   * @param amount The amount of tokens to burn
   */
  function _burn(address account, uint128 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply - amount;

    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance - amount;
  }
}
