// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

library Errors {
    error ErrorToReplace();

    // PoolFactory errors
    error PoolAlreadyExists(bytes32 salt, address existingPoolAddress);

    // PoolStoreUtils errors
    error PoolNotFound(address key);

    // SupplyUtils errors
    error EmptySupplyAmounts();



    // RoleModule errors
    error Unauthorized(address msgSender, string role);

    // RoleStore errors
    error ThereMustBeAtLeastOneRoleAdmin();
    error ThereMustBeAtLeastOneTimelockMultiSig();

    //token
    error EmptyBurnAmounts();
    error EmptyMintAmounts();

}
