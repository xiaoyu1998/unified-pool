// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../role/RoleModule.sol";
import "../data/DataStore.sol";
import "../error/Errors.sol";
import "../bank/StrictBank.sol";
import "../pool/PoolUtils.sol";
import "../utils/WadRayMath.sol";
import "./ScaledToken.sol";

import "../utils/Printer.sol";

// @title PoolToken
// @dev The pool token for a pool, stores funds for the pool and keeps track
// of the liquidity owners
contract PoolToken is RoleModule, ScaledToken, StrictBank {
	using WadRayMath for uint256;
	event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);
    
	address internal _underlyingAsset;

    mapping(address => uint256) private _Collaterals;
	uint256 private _totalCollateral;

    constructor(
    	RoleStore _roleStore, 
    	DataStore _dataStore,
    	address underlyingAsset_
    ) ScaledToken("UF_POOL_TOKEN", "UF_POOL_TOKEN", 0) StrictBank(_roleStore, _dataStore) {
    	_underlyingAsset = underlyingAsset_;
    }

	/// @inheritdoc IERC20
	function balanceOf(
	    address account
	) public view virtual override(IndexERC20) returns (uint256) {
	    return super.balanceOf(account)
	    	.rayMul(PoolUtils.getPoolNormalizedLiquidityIndex(address(dataStore), _underlyingAsset));
	}

	/// @inheritdoc IERC20
	function totalSupply() public view virtual override(IndexERC20) returns (uint256) {
		uint256 currentSupplyScaled = super.totalSupply();
		if (currentSupplyScaled == 0) {return 0;}
		return currentSupplyScaled
			.rayMul(PoolUtils.getPoolNormalizedLiquidityIndex(address(dataStore), _underlyingAsset));
	}

    // @dev mint pool tokens to an account
    // @param account the account to mint to
    // @param amount the amount of tokens to mint
    function mint(
    	address to, 
    	uint256 amount, 
    	uint256 index
    ) external virtual onlyController {
      	_mintScaled(to, amount, index);
    }

    // @dev burn pool tokens from an account
    // @param account the account to burn tokens for
    // @param amount the amount of tokens to burn
    function burn(
    	address from, 
    	address to, 
    	uint256 amount, 
    	uint256 index,
    	uint256 unclaimedFee
    ) external virtual onlyController {
		_burnScaled( from, to, amount, index);
		if (to != address(this)) {
	         //TODO move to validation module
	         uint256 _availableLiquidity = availableLiquidity(unclaimedFee);
			 if (amount > _availableLiquidity){
			 	 revert Errors.InsufficientAvailableLiquidity(amount, _availableLiquidity);
			 }

			 _transferOut(_underlyingAsset, to, amount);
		}       
    }

	function transferOnLiquidation(
		address from,
		address to,
		uint256 amount
	) external virtual onlyController {
		// Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
		// so no need to emit a specific event here
		_transfer(from, to, amount);
	}

	function _transfer(
		address from, 
		address to, 
		uint256 amount
	) internal override virtual {
		uint256 index = PoolUtils.getPoolNormalizedLiquidityIndex(address(dataStore), _underlyingAsset);

		super._transfer(from, to, amount, index);

		emit BalanceTransfer(from, to, amount.rayDiv(index), index);
	}

	function underlyingAsset() public view returns (address) {
		return _underlyingAsset;
	}

	function transferOutUnderlyingAsset(
        address receiver,
        uint256 amount
    ) external onlyController {
        _transferOut(_underlyingAsset, receiver, amount);
    }

	function syncUnderlyingAssetBalance() external onlyController {
        _syncTokenBalance(_underlyingAsset);
    }

	function addCollateral(
		address account, 
		uint256 amount
	) public onlyController returns (uint256) {
        _Collaterals[account] = _Collaterals[account] + amount;
        _totalCollateral   = _totalCollateral + amount;

        return _Collaterals[account];
	}

	function removeCollateral(
		address account, 
		uint256 amount
	) public onlyController returns (uint256) {
		if( _Collaterals[account] < amount){
			revert Errors.InsufficientCollateralAmount(amount, _Collaterals[account]);
		}
        _Collaterals[account] = _Collaterals[account] - amount;
        _totalCollateral   = _totalCollateral - amount;

        return _Collaterals[account];
	}

	function balanceOfCollateral(
		address account
	) public view  returns (uint256)   {
		return _Collaterals[account];
	}

	function totalCollateral() public view  returns (uint256) {
		return _totalCollateral;
	}

	function availableLiquidity(uint256 unclaimedFee) public view returns (uint256) {
		Printer.log("totalCollateral", totalCollateral());
		Printer.log("balanceOf", IERC20(_underlyingAsset).balanceOf(address(this)));
		return IERC20(_underlyingAsset).balanceOf(address(this)) - totalCollateral() - unclaimedFee;
	}

    function approveLiquidity(address spender, uint256 value) public onlyController returns (bool) {
    	return IERC20(_underlyingAsset).approve(spender, value);
    }


}