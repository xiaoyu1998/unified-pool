// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../dex/IDex2.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract OracleDex {

    uint8 internal constant DECIMALS = 12;
    uint256 internal constant X192 = 0x1000000000000000000000000000000000000000000000000;
    //uint256 internal constant NUMERATOR2 = 0xE8D4A510;//10**12

    address public immutable dex;
    address public immutable underlyingAsset;
    address public immutable underlyingAssetUsd;

    constructor(
        address _dex,
        address _underlyingAsset,
        address _underlyingAssetUsd
    ) {
        dex = _dex;
        underlyingAsset = _underlyingAsset;
        underlyingAssetUsd = _underlyingAssetUsd;
    }

    function latestRoundData() external view returns (
        uint80,
        int256,
        uint256,
        uint256,
        uint80
    ){
        uint256 sqrtPriceX96 = IDex2(dex).getSqrtPriceX96(underlyingAsset, underlyingAssetUsd);
        int256 answer = int256(calcPrice(sqrtPriceX96));
        return (
            uint80(0), // roundId
            answer, // answer
            0, // startedAt
            block.timestamp, // updatedAt
            uint80(0) // answeredInRound
        );
    }
    
    function decimals() public pure returns(uint8) {
        return DECIMALS;
    }

    function calcPrice(uint256 sqrtPriceX96) public view returns(uint256) {
        uint256 dec = decimals();
        uint256 numerator1 =uint256(sqrtPriceX96) *uint256(sqrtPriceX96);  
        uint256 numerator2 =10**dec; 

        uint256 price;
        if (underlyingAsset < underlyingAssetUsd) {
            price = Math.mulDiv(numerator1, numerator2, X192);
        } else {
            price = Math.mulDiv(numerator2, X192, numerator1);
        }
        return price;
    }

}
