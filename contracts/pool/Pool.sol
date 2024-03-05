// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;


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
        address underlyingTokenAddress;
        address interestRateStrategyAddress;
        uint256 Configration;
        uint128 liquidityIndex;
        uint128 LiquidityRate;
        uint128 borrowIndex;
        uint128 borrowRate;
        uint40  lastUpdateTimestamp;
        address poolTokenAddress;
        address debtTokenAddress;
        uint128 unclaimPoolFee;
        //uint256 poolFeeFactor;
    }

}
