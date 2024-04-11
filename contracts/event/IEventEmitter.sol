// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IEventEmitter {

    function emitSupply(
        address underlyingAsset,
        address account,
        address to,
        uint256 SupplyAmount
    ) external;

    function emitWithdraw(
        address underlyingAsset,
        address account,
        address to,
        uint256 withdrawAmount
    ) external;

    function emitDeposit(
        address underlyingAsset,
        address account,
        uint256 depositAmount
    ) external;

    function emitRedeem(
        address underlyingAsset,
        address account,
        address to,
        uint256 redeemAmount
    ) external;

    function emitBorrow(
        address underlyingAsset,
        address account,
        uint256 borrowAmount,
        uint256 borrowRate
    ) external;

    function emitRepay(
        address underlyingAsset,
        address repayer,
        uint256 repayAmount,
        bool useCollateral
    ) external;
}
