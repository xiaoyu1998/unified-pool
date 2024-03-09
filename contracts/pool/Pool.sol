// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;


library Pool {
  // struct PoolConfiguration {
  //   //bit 0-15: LTV
  //   //bit 16-31: Liq. threshold
  //   //bit 32-47: Liq. bonus
  //   //bit 48-55: Decimals
  //   //bit 56: reserve is active
  //   //bit 57: reserve is frozen
  //   //bit 58: borrowing is enabled
  //   //bit 59: stable rate borrowing enabled
  //   //bit 60: asset is paused
  //   //bit 61: borrowing in isolation mode is enabled
  //   //bit 62: siloed borrowing enabled
  //   //bit 63: flashloaning enabled
  //   //bit 64-79: reserve factor
  //   //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
  //   //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
  //   //bit 152-167 liquidation protocol fee
  //   //bit 168-175 eMode category
  //   //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
  //   //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
  //   //bit 252-255 unused
  //   uint256 data;
  // }
    struct Props {
        uint256 keyId;
        uint256 configration;
        uint256 liquidityIndex;
        uint256 liquidityRate;
        uint256 borrowIndex;
        uint256 borrowRate;
        uint256 lastUpdateTimestamp;
        uint256 totalPoolFee;
        address underlyingAsset;
        address interestRateStrategy;
        address poolToken;
        address debtToken;
        uint256 feeFactor;
    }

    function keyId(Props memory props) internal pure returns (uint256) {
        return props.keyId;
    }

    function setKeyId(Props memory props, uint256 value) internal pure {
        props.keyId = value;
    }

    function configration(Props memory props) internal pure returns (uint256) {
        return props.configration;
    }

    function setConfigration(Props memory props, uint256 value) internal pure {
        props.configration = value;
    }


    function liquidityIndex(Props memory props) internal pure returns (uint256) {
        return props.liquidityIndex;
    }

    function setLiquidityIndex(Props memory props, uint256 value) internal pure {
        props.liquidityIndex = value;
    }

    function liquidityRate(Props memory props) internal pure returns (uint256) {
        return props.liquidityRate;
    }

    function setLiquidityRate(Props memory props, uint256 value) internal pure {
        props.liquidityRate = value;
    }

    function borrowIndex(Props memory props) internal pure returns (uint256) {
        return props.borrowIndex;
    }

    function setBorrowIndex(Props memory props, uint256 value) internal pure {
        props.borrowIndex = value;
    }

    function borrowRate(Props memory props) internal pure returns (uint256) {
        return props.borrowRate;
    }

    function setBorrowRate(Props memory props, uint256 value) internal pure {
        props.borrowRate = value;
    }

    function lastUpdateTimestamp(Props memory props) internal pure returns (uint256) {
        return props.lastUpdateTimestamp;
    }

    function setLastUpdateTimestamp(Props memory props, uint256 value) internal pure {
        props.lastUpdateTimestamp = value;
    }

    function unclaimPoolFee(Props memory props) internal pure returns (uint256) {
        return props.unclaimPoolFee;
    }

    function setUnclaimPoolFee(Props memory props, uint256 value) internal pure {
        props.unclaimPoolFee = value;
    }

    function incrementClaimableFeeAmount(Props memory props, uint256 value) internal pure returns (uint256) {
        props.unclaimPoolFee += value;
    }

    function underlyingAsset(Props memory props) internal pure returns (address) {
        return props.underlyingAsset;
    }

    function setUnderlyingToken(Props memory props, address value) internal pure {
        props.underlyingAsset = value;
    }

    function interestRateStrategy(Props memory props) internal pure returns (address) {
        return props.interestRateStrategy;
    }

    function setInterestRateStrategy(Props memory props, address value) internal pure {
        props.interestRateStrategy = value;
    }

    function poolToken(Props memory props) internal pure returns (address) {
        return props.poolToken;
    }

    function setPoolToken(Props memory props, address value) internal pure {
        props.poolToken = value;
    }

    function debtTokeny(Props memory props) internal pure returns (address) {
        return props.debtToken;
    }

    function setDebtTokeny(Props memory props, address value) internal pure {
        props.debtTokeny = value;
    }

}
