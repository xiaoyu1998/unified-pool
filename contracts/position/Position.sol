// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;


library Position {

    struct Props {
        address account;
        uint256 collateralAndDebtPools;
    }

    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(Props memory props, address value) internal pure {
        props.account = value;
    }

    function collateralAndDebtPools(Props memory props) internal pure returns (uint256) {
        return props.collateralAndDebtPools;
    }

    function setCollateralAndDebtPools(Props memory props, uint256 value) internal pure {
        props.collateralAndDebtPools = value;
    }

    function setAsCollateral(Props memory props, uint256 id, bool isCollateral) internal pure {
        //props.collateralAndDebtPools = value;
    }

    function setAsDebt(Props memory props, uint256 id, bool isDebt) internal pure {
        //props.collateralAndDebtPools = value;
    }

}
