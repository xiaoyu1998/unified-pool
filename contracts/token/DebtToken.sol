// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";
import "../data/DataStore.sol";
import "../error/Errors.sol";
import "../pool/PoolUtils.sol";
import "../utils/WadRayMath.sol";
import "./ScaledToken.sol";

// @title DebtToken
// @dev The Debt token for a pool,  keeps track of the debt owners
contract DebtToken is RoleModule, ScaledToken {
	using WadRayMath for uint256;

	DataStore public immutable dataStore;
	address internal _underlyingAsset;

    constructor(
    	RoleStore _roleStore, 
    	DataStore _dataStore, 
    	address underlyingAsset_
    ) RoleModule(_roleStore) ScaledToken("UF_DEBT_TOKEN", "UF_DEBT_TOKEN", 0)  {
    	dataStore = _dataStore;
    	_underlyingAsset = underlyingAsset_;
    }

	/// @inheritdoc IERC20
	function balanceOf(
	    address account
	) public view virtual override returns (uint256) {

		uint256 currentSupplyScaled = super.balanceOf(account);
	    if (currentSupplyScaled == 0) { return 0; }
	    return currentSupplyScaled.rayMul(PoolUtils.getPoolNormalizedBorrowingIndex(address(dataStore), _underlyingAsset));
	}

	/// @inheritdoc IERC20
	function totalSupply() public view virtual override returns (uint256) {
		uint256 currentSupplyScaled = super.totalSupply();
		if (currentSupplyScaled == 0) {return 0;}
		return currentSupplyScaled.rayMul(PoolUtils.getPoolNormalizedBorrowingIndex(address(dataStore), _underlyingAsset));
	}


    // @dev mint market tokens to an account
    // @param account the account to mint to
    // @param amount the amount of tokens to mint
    function mint(
    	address to, 
    	uint256 amount, 
    	uint256 index
    ) external virtual onlyController returns (bool, uint256) {
    	//_mintScaled(to, amount, index);
      	return (_mintScaled(to, amount, index), scaledTotalSupply());
    }

    // @dev burn market tokens from an account
    // @param account the account to burn tokens for
    // @param amount the amount of tokens to burn
    function burn(
    	address from, 
    	uint256 amount, 
    	uint256 index
    ) external virtual onlyController returns (uint256) {
		_burnScaled(from, address(0), amount, index);
		return scaledTotalSupply();  
    }


	function transfer(address, uint256) external virtual override returns (bool) {
		revert Errors.DebtTokenOperationNotSupported();
	}

	function allowance(address, address) external view virtual override returns (uint256) {
		revert Errors.DebtTokenOperationNotSupported();
	}

	function approve(address, uint256) external virtual override returns (bool) {
		revert Errors.DebtTokenOperationNotSupported();
	}

	function transferFrom(address, address, uint256) external virtual override returns (bool) {
		revert Errors.DebtTokenOperationNotSupported();
	}

	function increaseAllowance(address, uint256) external virtual override returns (bool) {
		revert Errors.DebtTokenOperationNotSupported();
	}

	function decreaseAllowance(address, uint256) external virtual override returns (bool) {
		revert Errors.DebtTokenOperationNotSupported();
	}

	function underlyingAsset() external view returns (address) {
		return _underlyingAsset;
	}


}