// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "./Position.sol";


// @title PositionUtils
// @dev Library for Position functions
library PositionUtils {
    using Position for Position.Props;
    
    //TODO:should change to multi-position
    function getPositionKey(address account) internal pure returns (bytes32) {
        bytes32 key = keccak256(abi.encode(account));
        return key;
    }



}