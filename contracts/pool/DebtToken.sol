// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// @title DebtToken
// @dev The Debt token for a pool,  keeps track of the debt owners
contract DebToken is ScaledToken {
	address internal _underlyingTokenAddress;
	address internal _poolKey;

    constructor(RoleStore _roleStore, DataStore _dataStore) ScaledToken("UF_DEBT_TOKEN", "UF_DEBT_TOKEN")  {
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
	) public view virtual override returns (uint256) {

		uint256 currentSupplyScaled = super.balanceOf(user);
	    if (currentSupplyScaled == 0) { return 0; }
	    return currentSupplyScaled.rayMul(PoolUtils.getPoolNormalizedDebt(dataStore, _poolKey));
	}

	/// @inheritdoc IERC20
	function totalSupply() public view virtual overridereturns (uint256) {
		uint256 currentSupplyScaled = super.totalSupply();
		if (currentSupplyScaled == 0) {return 0;}
		return currentSupplyScaled.rayMul(PoolUtils.getPoolNormalizedDebt(dataStore, _poolKey));
	}


    // @dev mint market tokens to an account
    // @param account the account to mint to
    // @param amount the amount of tokens to mint
    function mint(address receiver, uint256 amount, uint256 index
    ) external virtual override  onlyController returns (bool) {
      	return (_mintScaled(receiver, amount, index), scaledTotalSupply());
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
		return _underlyingTokenAddress;
	}


}