// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../bank/Bank.sol";

// @title PoolToken
// @dev The pool token for a pool, stores funds for the pool and keeps track
// of the liquidity owners
contract PoolToken is ScaledToken, Bank {
	address internal _underlyingTokenAddress;
	address internal _poolKey;

    mapping(address => uint256) private _Collaterals;
	uint256 private _totalCollateral;

    constructor(RoleStore _roleStore, DataStore _dataStore) ScaledToken("UF_POOL_TOKEN", "UF_POOL_TOKEN") Bank(_roleStore, _dataStore) {
    }

	/// @inheritdoc IInitializableDebtToken
	function initialize(
		address poolKey,
		address underlyingTokenAddress
	) external override onlyController {
		_poolKey                = poolKey;		
		_underlyingTokenAddress = underlyingAsset;
	}

	/// @inheritdoc IERC20
	function balanceOf(
	    address user
	) public view virtual override(IncentivizedERC20, IERC20) returns (uint256) {
	    return super.balanceOf(user).rayMul(PoolUtils.getPoolNormalizedIncome(dataStore, _poolKey));
	}

	/// @inheritdoc IERC20
	function totalSupply() public view virtual override(IERC20) returns (uint256) {
		uint256 currentSupplyScaled = super.totalSupply();
		if (currentSupplyScaled == 0) {return 0;}
		return currentSupplyScaled.rayMul(PoolUtils.getPoolNormalizedIncome(dataStore, _poolKey));
	}


    // @dev mint pool tokens to an account
    // @param account the account to mint to
    // @param amount the amount of tokens to mint
    function mint(address receiver, uint256 amount, uint256 index
    ) external virtual override  onlyController returns (bool) {
      	return _mintScaled(pool, receiver, amount, index);
    }

    // @dev burn pool tokens from an account
    // @param account the account to burn tokens for
    // @param amount the amount of tokens to burn
    function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index
    ) external virtual override onlyController return (bool) {
		_burnScaled(pool, from, receiverOfUnderlying, amount, index);
		if (receiverOfUnderlying != address(this)) {

         //todo move to validation module
         uint256 availableBalance = IERC20(token).balanceOf(address(this)) - totalCollateral();
		 if(amount > availableBalance){
		 	revert InsufficientBalanceAfterSubstractionCollateral(amount, availableBalance)
		 }

		 IERC20(_underlyingTokenAddress).safeTransfer(receiverOfUnderlying, amount);
		}       
    }

	function _transfer(address from, address to, uint256 amount, bool validate) internal virtual {
		address underlyingAsset = _underlyingTokenAddress;

		//Pool.Props memory pool = PoolStoreUtils.get(dataStore, _poolKey)
		// if(pool == null){
		// 	revert erros.PoolNotFound(_poolKey);
		// }
		uint256 index = PoolUtils.getPoolNormalizedIncome(dataStore, _poolKey);

		uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
		uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

		super._transfer(from, to, amount, index);

		// if (validate) {
		//   POOL.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore);
		// }
		//emit BalanceTransfer(from, to, amount.rayDiv(index), index);
	}

	function _transfer(address from, address to, uint128 amount) internal virtual override {
		_transfer(from, to, amount, true);
	}



	function addCollateral(address user, uint256 amount) public onlyController {
        _Collaterals[user] = _Collaterals[user] + amount;
        _totalCollateral = _totalCollateral + amount;
	}

	function removeCollateral(address user, uint256 amount) public onlyController {
        _Collaterals[user] = _Collaterals[user] - amount;
        _totalCollateral = _totalCollateral - amount;
	}

	function balanceOfCollateral(address user) public view  returns (uint256)   {
		return _Collaterals[user];
	}

	function totalCollateral() public view  returns (uint256) {
		return _totalCollateral;
	}


	/// @inheritdoc IPoolToken
	function UNDERLYING_TOKEN_ADDRESS() external view override returns (address) {
		return _underlyingTokenAddress;
	}


}