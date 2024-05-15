// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/Keys.sol";
import "../data/IDataStore.sol";

import "./Position.sol";

/**
 * @title PositionStoreUtils
 * @dev Library for position storage functions
 */
library PositionStoreUtils {
    using Position for Position.Props;

    bytes32 public constant UNDERLYING_ASSET = keccak256(abi.encode("UNDERLYING_ASSET"));
    bytes32 public constant ACCOUNT = keccak256(abi.encode("ACCOUNT"));
    bytes32 public constant ENTRY_LONG_PRICE = keccak256(abi.encode("ENTRY_LONG_PRICE"));
    bytes32 public constant ACC_LONG_AMOUNT = keccak256(abi.encode("ACC_LONG_AMOUNT"));
    bytes32 public constant ENTRY_SHORT_PRICE = keccak256(abi.encode("ENTRY_SHORT_PRICE"));
    bytes32 public constant ACC_SHORT_AMOUNT = keccak256(abi.encode("ACC_SHORT_AMOUNT"));
    bytes32 public constant IS_USD = keccak256(abi.encode("IS_USD"));
    bytes32 public constant POSITION_TYPE = keccak256(abi.encode("POSITION_TYPE"));
    bytes32 public constant HAS_COLLATERAL = keccak256(abi.encode("HAS_COLLATERAL"));
    bytes32 public constant HAS_DEBT = keccak256(abi.encode("HAS_DEBT"));
    //bytes32 public constant IS_LIQUIDATED = keccak256(abi.encode("IS_LIQUIDATED"));

    function get(address dataStoreAddress, bytes32 key) external view returns (Position.Props memory) {
        IDataStore dataStore = IDataStore(dataStoreAddress);
        Position.Props memory position;
        if (!dataStore.containsBytes32(Keys.POSITION_LIST, key)) {
            return position;
        }

        position.account = dataStore.getAddress(
            keccak256(abi.encode(key, ACCOUNT))
        );

        position.underlyingAsset = dataStore.getAddress(
            keccak256(abi.encode(key, UNDERLYING_ASSET))
        );

        position.entryLongPrice = dataStore.getUint(
            keccak256(abi.encode(key, ENTRY_LONG_PRICE))
        );

        position.accLongAmount = dataStore.getUint(
            keccak256(abi.encode(key, ACC_LONG_AMOUNT))
        );

        position.entryShortPrice = dataStore.getUint(
            keccak256(abi.encode(key, ENTRY_SHORT_PRICE))
        );

        position.accShortAmount = dataStore.getUint(
            keccak256(abi.encode(key, ACC_SHORT_AMOUNT))
        );

        position.positionType = dataStore.getUint(
            keccak256(abi.encode(key, POSITION_TYPE))
        );

        position.hasCollateral = dataStore.getBool(
            keccak256(abi.encode(key, HAS_COLLATERAL))
        );

        position.hasDebt = dataStore.getBool(
            keccak256(abi.encode(key, HAS_DEBT))
        );

        // position.isLiquidated = dataStore.getBool(
        //     keccak256(abi.encode(key, IS_LIQUIDATED))
        // );

        return position;
    }

    function set(address dataStoreAddress, bytes32 key, Position.Props memory position) external {
        IDataStore dataStore = IDataStore(dataStoreAddress);
        dataStore.addBytes32(
            Keys.POSITION_LIST,
            key
        );

        dataStore.addBytes32(
            Keys.accountPositionListKey(position.account),
            key
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, ACCOUNT)),
            position.account
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, UNDERLYING_ASSET)),
            position.underlyingAsset
        );

        dataStore.setUint(
            keccak256(abi.encode(key, ENTRY_LONG_PRICE)),
            position.entryLongPrice
        );

        dataStore.setUint(
            keccak256(abi.encode(key, ACC_LONG_AMOUNT)),
            position.accLongAmount
        );

        dataStore.setUint(
            keccak256(abi.encode(key, ENTRY_SHORT_PRICE)),
            position.entryShortPrice
        );

        dataStore.setUint(
            keccak256(abi.encode(key, ACC_SHORT_AMOUNT)),
            position.accShortAmount
        );

        dataStore.setUint(
            keccak256(abi.encode(key, POSITION_TYPE)),
            position.positionType
        );

        dataStore.setBool(
            keccak256(abi.encode(key, HAS_COLLATERAL)),
            position.hasCollateral
        );

        dataStore.setBool(
            keccak256(abi.encode(key, HAS_DEBT)),
            position.hasDebt
        );

        // dataStore.setBool(
        //     keccak256(abi.encode(key, IS_LIQUIDATED)),
        //     position.isLiquidated
        // );

    }

    function remove(address dataStoreAddress, bytes32 key, address account) external {
        IDataStore dataStore = IDataStore(dataStoreAddress);
        if (!dataStore.containsBytes32(Keys.POSITION_LIST, key)) {
            revert Errors.PositionNotFound(key);
        }

        dataStore.removeBytes32(
            Keys.POSITION_LIST,
            key
        );

        dataStore.removeBytes32(
            Keys.accountPositionListKey(account),
            key
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, ACCOUNT))
        );
        
        dataStore.removeAddress(
            keccak256(abi.encode(key, UNDERLYING_ASSET))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, ENTRY_LONG_PRICE))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, ACC_LONG_AMOUNT))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, ENTRY_SHORT_PRICE))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, ACC_SHORT_AMOUNT))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, POSITION_TYPE))
        );

        dataStore.removeBool(
            keccak256(abi.encode(key, HAS_COLLATERAL))
        );

        dataStore.removeBool(
            keccak256(abi.encode(key, HAS_DEBT))
        );

        // dataStore.removeBool(
        //     keccak256(abi.encode(key, IS_LIQUIDATED))
        // );
    }

    function setHealthFactorLiquidationThreshold(address dataStore, uint256 threshold) external  {
        IDataStore(dataStore).setUint(Keys.HEALTH_FACTOR_LIQUIDATION_THRESHOLD, threshold);
    }

    function setDebtMultiplierFactorForRedeem(address dataStore, uint256 multiplierFactor) external  {
        IDataStore(dataStore).setUint(Keys.DEBT_MULTIPLIER_FACTOR_FOR_REDEEM, multiplierFactor);
    }

    function setHealthFactorCollateralRateThreshold(address dataStore, address underlyingAsset, uint256 threshold) external  {
        IDataStore(dataStore).setUint(Keys.healthFactorCollateralRateThresholdKey(underlyingAsset), threshold);
    }

    function getHealthFactorLiquidationThreshold(address dataStore) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.HEALTH_FACTOR_LIQUIDATION_THRESHOLD);
    }

    function getDebtMultiplierFactorForRedeem(address dataStore) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.DEBT_MULTIPLIER_FACTOR_FOR_REDEEM);
    }
    
    function getHealthFactorCollateralRateThreshold(address dataStore, address underlyingAsset) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.healthFactorCollateralRateThresholdKey(underlyingAsset));
    }


    function getPositionCount(address dataStore) internal view returns (uint256) {
        //IDataStore dataStore = IDataStore(dataStoreAddress);
        return IDataStore(dataStore).getAddressCount(Keys.POSITION_LIST);
    }

    function getPositionKeys(address dataStore, uint256 start, uint256 end) internal view returns (address[] memory) {
        //IDataStore dataStore = IDataStore(dataStoreAddress);
        return IDataStore(dataStore).getAddressValuesAt(Keys.POSITION_LIST, start, end);
    }

    function getAccountPositionCount(address dataStore, address account) internal view returns (uint256) {
        //IDataStore dataStore = IDataStore(dataStoreAddress);
        return IDataStore(dataStore).getBytes32Count(Keys.accountPositionListKey(account));
    }

    function getAccountPositionKeys(address dataStore, address account, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        //IDataStore dataStore = IDataStore(dataStoreAddress);
        return IDataStore(dataStore).getBytes32ValuesAt(Keys.accountPositionListKey(account), start, end);
    }
}