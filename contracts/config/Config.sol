// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../role/RoleModule.sol";
import "../utils/BasicMulticall.sol";

// @title Config
contract Config is ReentrancyGuard, RoleModule, BasicMulticall {

    DataStore public immutable dataStore;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) {
        dataStore = _dataStore;
    }

    modifier onlyKeeper() {
        if (
            !roleStore.hasRole(msg.sender, Role.LIMITED_CONFIG_KEEPER) &&
            !roleStore.hasRole(msg.sender, Role.CONFIG_KEEPER)
        ) {
            revert Errors.Unauthorized(msg.sender, "LIMITED / CONFIG KEEPER");
        }

        _;
    }

    function setHealthFactorCollateralRateThreshold(
        uint256 threshold
    ) external onlyConfigKeeper nonReentrant {

        dataStore.setUint(Keys.HEALTH_FACTOR_COLLATERAL_RATE_THRESHOLD, threshold);
    }


}
