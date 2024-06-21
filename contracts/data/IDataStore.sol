// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;


interface IDataStore {
    function getUint(bytes32 key) external view returns (uint256);
    function setUint(bytes32 key, uint256 value) external returns (uint256);
    function removeUint(bytes32 key) external;

    function containsAddress(bytes32 setKey, address value) external view returns (bool);
    function addAddress(bytes32 setKey, address value) external;
    function getAddress(bytes32 key) external view returns (address);
    function setAddress(bytes32 key, address value) external returns (address);
    function removeAddress(bytes32 key) external;
    function removeAddress(bytes32 setKey, address value) external; 
    function getAddressCount(bytes32 setKey) external view returns (uint256);
    function getAddressValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (address[] memory);

    function getBool(bytes32 key) external view returns (bool);
    function setBool(bytes32 key, bool value) external returns (bool);
    function removeBool(bytes32 key) external;

    function getBytes32(bytes32 key) external view returns (bytes32);
    function setBytes32(bytes32 key, bytes32 value) external returns (bytes32);
    function removeBytes32(bytes32 key) external;

    function containsBytes32(bytes32 setKey, bytes32 value) external view returns (bool);
    function getBytes32Count(bytes32 setKey) external view returns (uint256);
    function addBytes32(bytes32 setKey, bytes32 value) external;
    function removeBytes32(bytes32 setKey, bytes32 value) external; 
    function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory);

    function incrementUint(bytes32 key, uint256 value) external returns (uint256);
}
