// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;


library Pool {
    struct Props {
        uint256 keyId;
        uint256 liquidityIndex;
        uint256 liquidityRate;
        uint256 borrowIndex;
        uint256 borrowRate;
        
        address interestRateStrategy;
        address underlyingAsset;
        address poolToken;
        address debtToken;

        uint256 configuration;
        uint256 totalFee;
        uint256 unclaimedFee;
        uint256 lastUpdateTimestamp;
    }


    function incrementFee(Props memory props, uint256 value) internal pure {
        props.totalFee     += value;
        props.unclaimedFee += value;
    }

}
