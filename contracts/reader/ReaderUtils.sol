// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../data/DataStore.sol";
import "../data/Keys.sol";

import "../token/IPoolToken.sol";

// @title OracleUtils
library ReaderUtils {

    struct PoolLiquidity {
        address underlyingAsset;
        uint256 scaledTotalSupply;
        uint256 totalSupply;
        uint256 totalCollateral;
        uint256 availableLiquidity;
    }

    struct AccountLiquidity {
        address underlyingAsset;
        address account;
        uint256 balance;
        uint256 scaled;
        uint256 collateral;
    }

    function getPoolLiquidity(DataStore dataStore, address poolTokenAddress) public view returns (PoolLiquidity memory) {
        IPoolToken poolToken   = IPoolToken(poolTokenAddress);

        PoolLiquidity memory poolLiquidity = PoolLiquidity(
            poolToken.underlyingAsset(),
            poolToken.scaledTotalSupply(),
            poolToken.totalSupply(),
            poolToken.totalCollateral(),
            poolToken.availableLiquidity()
        );
        return poolLiquidity;
    }

    function getAccountLiquidity(
        DataStore dataStore, 
        address poolTokenAddress, 
        address account
    ) public view returns (AccountLiquidity memory) {
        IPoolToken poolToken   = IPoolToken(poolTokenAddress);

        AccountLiquidity memory accountLiquidity = AccountLiquidity(
            poolToken.underlyingAsset(),
            account,
            poolToken.balanceOf(account),
            poolToken.scaledBalanceOf(account),
            poolToken.balanceOfCollateral(account)
        );
        return accountLiquidity;
    }
    
}
