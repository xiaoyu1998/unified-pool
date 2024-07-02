// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../utils/PayableMulticall.sol";
import "../utils/AccountUtils.sol";

import "../data/DataStore.sol";
//import "../event/EventEmitter.sol";
import "../token/TokenUtils.sol";

import "./Router.sol";

contract BaseRouter is ReentrancyGuard, PayableMulticall, RoleModule {
    using SafeERC20 for IERC20;

    Router public immutable router;
    DataStore public immutable dataStore;

    constructor(
        Router _router,
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) {
        router = _router;
        dataStore = _dataStore;
    }

    // @dev Sends the given amount of tokens to the given address
    function sendTokens(address token, address receiver, uint256 amount) external payable nonReentrant {
        AccountUtils.validateReceiver(receiver);
        address account = msg.sender;
        router.pluginTransfer(token, account, receiver, amount);
    }

}
