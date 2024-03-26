// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

/**
 * @title Role
 * @dev Library for role keys
 */
library Role {
    /**
     * @dev The ROLE_ADMIN role.
     */
    bytes32 public constant ROLE_ADMIN = keccak256(abi.encode("ROLE_ADMIN"));
    /**
     * @dev The CONFIG_KEEPER role.
     */
    bytes32 public constant CONFIG_KEEPER = keccak256(abi.encode("CONFIG_KEEPER"));
    /**
     * @dev The CONTROLLER role.
     */
    bytes32 public constant CONTROLLER = keccak256(abi.encode("CONTROLLER"));

    /**
     * @dev The GOV_TOKEN_CONTROLLER role.
     */
    bytes32 public constant GOV_TOKEN_CONTROLLER = keccak256(abi.encode("GOV_TOKEN_CONTROLLER"));

    /**
     * @dev The ROUTER_PLUGIN role.
     */
    bytes32 public constant ROUTER_PLUGIN = keccak256(abi.encode("ROUTER_PLUGIN"));

    /**
     * @dev The POOL_KEEPER role.
     */
    bytes32 public constant POOL_KEEPER = keccak256(abi.encode("POOL_KEEPER"));

    /**
     * @dev The FEE_KEEPER role.
     */
    bytes32 public constant FEE_KEEPER = keccak256(abi.encode("FEE_KEEPER"));

    /**
     * @dev The FEE_DISTRIBUTION_KEEPER role.
     */
    bytes32 public constant FEE_DISTRIBUTION_KEEPER = keccak256(abi.encode("FEE_DISTRIBUTION_KEEPER"));

    /**
     * @dev The PRICING_KEEPER role.
     */
    bytes32 public constant PRICING_KEEPER = keccak256(abi.encode("PRICING_KEEPER"));
    /**
     * @dev The LIQUIDATION_KEEPER role.
     */
    bytes32 public constant LIQUIDATION_KEEPER = keccak256(abi.encode("LIQUIDATION_KEEPER"));

}
