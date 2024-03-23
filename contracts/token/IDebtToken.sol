// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IDebtToken {

    function mint(
        address to,
        uint256 amount,
        uint256 index
    ) external returns (bool, uint256);

    function burn(
        address from,
        uint256 amount,
        uint256 index
    ) external returns (uint256);

   function balanceOf(address account) external view  returns (uint256);
   function scaledBalanceOf(address account) external view returns (uint256);
   function scaledTotalSupply() external view returns (uint256);

    
}
