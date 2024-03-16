// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../token/ScaledToken.sol";

// @title DebtToken
// @dev The Debt token for a pool,  keeps track of the debt owners
contract DebToken is ScaledToken {
	address internal _underlyingAsset;
	// address internal _poolKey;

    constructor(
    	RoleStore _roleStore, 
    	DataStore _dataStore, 
    	address underlyingAsset
    ) ScaledToken("UF_DEBT_TOKEN", "UF_DEBT_TOKEN")  {
    	_underlyingAsset = underlyingAsset;
    }

	/// @inheritdoc IERC20
	function balanceOf(
	    address account
	) public view virtual override returns (uint256) {

		uint256 currentSupplyScaled = super.balanceOf(account);
	    if (currentSupplyScaled == 0) { return 0; }
	    return currentSupplyScaled.rayMul(PoolUtils.getPoolNormalizedBorrowingIndex(dataStore, _underlyingAsset));
	}

	/// @inheritdoc IERC20
	function totalSupply() public view virtual overridereturns (uint256) {
		uint256 currentSupplyScaled = super.totalSupply();
		if (currentSupplyScaled == 0) {return 0;}
		return currentSupplyScaled.rayMul(PoolUtils.getPoolNormalizedBorrowingIndex(dataStore, _underlyingAsset));
	}


    // @dev mint market tokens to an account
    // @param account the account to mint to
    // @param amount the amount of tokens to mint
    function mint(address to, uint256 amount, uint256 index
    ) external virtual override  onlyController returns (bool) {
      	return (_mintScaled(to, amount, index), scaledTotalSupply());
    }

    // @dev burn market tokens from an account
    // @param account the account to burn tokens for
    // @param amount the amount of tokens to burn
    function burn(address from, uint256 amount, uint256 index
    ) external virtual override onlyController return (bool) {
		_burnScaled(from, address(0), amount, index);
		return scaledTotalSupply();  
    }


	function transfer(address, uint256) external virtual override returns (bool) {
		revert(Errors.OPERATION_NOT_SUPPORTED);
	}

	function allowance(address, address) external view virtual override returns (uint256) {
		revert(Errors.OPERATION_NOT_SUPPORTED);
	}

	function approve(address, uint256) external virtual override returns (bool) {
		revert(Errors.OPERATION_NOT_SUPPORTED);
	}

	function transferFrom(address, address, uint256) external virtual override returns (bool) {
		revert(Errors.OPERATION_NOT_SUPPORTED);
	}

	function increaseAllowance(address, uint256) external virtual override returns (bool) {
		revert(Errors.OPERATION_NOT_SUPPORTED);
	}

	function decreaseAllowance(address, uint256) external virtual override returns (bool) {
		revert(Errors.OPERATION_NOT_SUPPORTED);
	}

	/// @inheritdoc IDebtToken
	function UNDERLYING_TOKEN_ADDRESS() external view override returns (address) {
		return _underlyingAssetAddress;
	}


}