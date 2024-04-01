// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;
import "../pool/PoolConfigurationUtils.sol";

library Position {

    struct Props {
        address account;
        address underlyingAsset;
        uint256 entryLongPrice;
        uint256 accLongAmount;
        uint256 entryShortPrice;
        uint256 accShortAmount;
        bool isLong;
        bool hasCollateral;
        bool hasDebt;
    }
    
}
