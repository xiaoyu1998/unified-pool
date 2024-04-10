// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;


// @title EventUtils
// @dev Library for Event definition and fucntion
library EventUtils {

	event Supply(
		address indexed pool,
		address user,
		address indexed to,
		uint256 amount
	);

	event Withdraw(
		address indexed pool, 
		address indexed user, 
		address indexed to, 
		uint256 amount
	);

	event Borrow(
		address indexed pool,
		address user,
		//address indexed to,
		uint256 amount,
		uint256 borrowRate
	);

	event Deposit(
		address indexed pool,
		address user,
		//address indexed to,
		uint256 amount
	);

	event Repay(
		address indexed pool,
		// address indexed to,
		address indexed repayer,
		uint256 amount,
		bool useCollateral
	);

	event Redeem(
		address indexed pool,
		address indexed redeemer,
		address indexed to,
		uint256 amount
	);

}