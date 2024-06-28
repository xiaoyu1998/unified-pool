// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../borrow/BorrowUtils.sol";

interface IPoolToken {

    function mint(
        address to,
        uint256 amount,
        uint256 index
    ) external;

    function burn(
        address from,
        address to, 
        uint256 amount,
        uint256 index,
        uint256 unclaimedFee
    ) external;

    function balanceOf(address account) external view  returns (uint256);
    function scaledBalanceOf(address account) external view returns (uint256);
    function scaledTotalSupply() external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function addCollateral(address account, uint256 amount) external returns (uint256);
    function removeCollateral(address account, uint256 amount) external returns (uint256);
    function balanceOfCollateral (address account) external view returns (uint256);
    function totalCollateral() external view  returns (uint256);

    function availableLiquidity(uint256 unclaimedFee) external view  returns (uint256);
    function recordTransferIn(address token) external returns (uint256);
    function recordTransferOut(address token) external returns (uint256);
    function transferOutUnderlyingAsset(
        address receiver,
        uint256 amount
    ) external;
    function approveLiquidity(
        address spender, 
        uint256 value
    ) external returns (bool);

    function syncUnderlyingAssetBalance() external;

    function underlyingAsset() external view  returns (address);
}
