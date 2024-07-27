// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./MintableERC20.sol";

import "../error/Errors.sol";
import "../utils/WadRayMath.sol";
 // @title ScaledToken 
 // @author Aave 
 // @notice Basic ERC20 implementation of scaled balance token
abstract contract ScaledToken is MintableERC20 {
    using WadRayMath for uint256;
    using SafeCast for uint256;


 // @dev Constructor.
 // @param name The name of the token
 // @param symbol The symbol of the token
 // @param decimals The number of decimals of the token
  constructor(
      string memory name,
      string memory symbol,
      uint8 decimals
  ) MintableERC20(name, symbol, decimals) {
    // Intentionally left blank
  }

  function scaledBalanceOf(address account) external view returns (uint256) {
      return super.balanceOf(account);
  }

  function getScaledUserBalanceAndSupply(
      address account
  ) external view returns (uint256, uint256) {
      return (super.balanceOf(account), super.totalSupply());
  }

  function scaledTotalSupply() public view virtual returns (uint256) {
      return super.totalSupply();
  }

  function getPreviousIndex(address account) external view virtual returns (uint256) {
      return _index[account];
  }


 // @notice Implements the basic logic to mint a scaled balance token.
 // @param to The address of the user that will receive the scaled tokens
 // @param amount The amount of tokens getting minted
 // @param index The next liquidity index of the reserve
 // @return `true` if the the previous balance of the user was 0
  function _mintScaled(
      address to,
      uint256 amount,
      uint256 index
  ) internal returns (bool) {
      uint256 amountScaled = amount.rayDiv(index);
      if (amountScaled == 0){
          revert Errors.EmptyMintAmounts();
      }

      uint256 scaledBalance = super.balanceOf(to);
      uint256 balanceIncrease = scaledBalance.rayMul(index) -
        scaledBalance.rayMul(_index[to]);

      _index[to] = index;

      _mint(to, amountScaled);

      uint256 amountToMint = amount + balanceIncrease;
      emit Transfer(address(0), to, amountToMint);
      emit Mint(address(0), to, amountToMint, balanceIncrease, index);

      return (scaledBalance == 0);
  }


 // @notice Implements the basic logic to burn a scaled balance token.
 // @dev In some instances, a burn transaction will emit a mint event
 // if the amount to burn is less than the interest that the user accrued
 // @param account The account which debt is burnt
 // @param to The address that will receive the underlying, if any
 // @param amount The amount getting burned
 // @param index The variable debt index of the reserve
  function _burnScaled(
      address account, 
      address to, 
      uint256 amount, 
      uint256 index
  ) internal returns (bool) {
      uint256 amountScaled = amount.rayDiv(index);
      if (amountScaled == 0){
          revert Errors.EmptyBurnAmounts();
      }

      uint256 scaledBalance = super.balanceOf(account);
      uint256 balanceIncrease = scaledBalance.rayMul(index) -
          scaledBalance.rayMul(_index[account]);

      _index[account] = index;

      _burn(account, amountScaled);

      if (balanceIncrease > amount) {
          uint256 amountToMint = balanceIncrease - amount;
          emit Transfer(address(0), account, amountToMint);
          emit Mint(account, account, amountToMint, balanceIncrease, index);
      } else {
          uint256 amountToBurn = amount - balanceIncrease;
          emit Transfer(account, address(0), amountToBurn);
          emit Burn(account, to, amountToBurn, balanceIncrease, index);
      }

      return (scaledBalance == amountScaled);
  }

  // @notice Implements the basic logic to burn all sbalance token.
 // @dev In some instances, a burn transaction will emit a burn event
 // @param account The account which debt is burnt
 // @param to The address that will receive the underlying, if any
  function _burnAll(
      address account,
      address to,
      uint256 index
  ) internal {
      uint256 scaledBalance = super.balanceOf(account);

      if (scaledBalance == 0){
          revert Errors.EmptyBurnAmounts();
      }
      uint256 balanceIncrease = scaledBalance.rayMul(index) -
          scaledBalance.rayMul(_index[account]);

      _index[account] = index;
      _burn(account, scaledBalance);

      uint256 amountToBurn = scaledBalance.rayMul(index);
      emit Transfer(account, address(0), amountToBurn);
      emit Burn(account, to, amountToBurn, balanceIncrease, index);
    
  }

 // @notice Implements the basic logic to transfer scaled balance tokens between two users
 // @dev It emits a mint event with the interest accrued per user
 // @param from The source address
 // @param to The destination address
 // @param amount The amount getting transferred
 // @param index The next liquidity index of the reserve
  function _transfer(
      address from, 
      address to, 
      uint256 amount, 
      uint256 index
  ) internal {
      uint256 fromScaledBalance = super.balanceOf(from);
      uint256 fromBalanceIncrease = fromScaledBalance.rayMul(index) -
          fromScaledBalance.rayMul(_index[from]);

      uint256 toScaledBalance = super.balanceOf(to);
      uint256 toBalanceIncrease = toScaledBalance.rayMul(index) -
          toScaledBalance.rayMul(_index[to]);

      _index[from] = index;
      _index[to] = index;

      super._transfer(from, to, amount.rayDiv(index));

      if (fromBalanceIncrease > 0) {
          emit Transfer(address(0), from, fromBalanceIncrease);
          emit Mint(_msgSender(), from, fromBalanceIncrease, fromBalanceIncrease, index);
      }
      if (from != to && toBalanceIncrease > 0) {
          emit Transfer(address(0), to, toBalanceIncrease);
          emit Mint(_msgSender(), to, toBalanceIncrease, toBalanceIncrease, index);
      }

      emit Transfer(from, to, amount);
  }
}
