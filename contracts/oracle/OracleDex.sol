// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../dex/IDex2.sol";
import "../utils/Printer.sol";
import "../error/Errors.sol";

contract OracleDex {

    uint256 internal constant X192 = 0x1000000000000000000000000000000000000000000000000;
    //uint256 internal constant NUMERATOR2 = 0xE8D4A510;//10**12

    address public immutable dex;
    address public immutable underlyingAsset;
    address public immutable underlyingAssetUsd;
    uint8 public immutable decimalsDelta;
    uint8 public immutable decimalsOracle_;

    constructor(
        address _dex,
        address _underlyingAsset,
        address _underlyingAssetUsd,
        uint8 _decimalsDelta,
        uint8 _decimalsOracle
    ) {
        dex = _dex;
        underlyingAsset = _underlyingAsset;
        underlyingAssetUsd = _underlyingAssetUsd;
        decimalsDelta = _decimalsDelta;
        decimalsOracle_ = _decimalsOracle;
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

        Printer.log("sqrtPriceX96", sqrtPriceX96);
        Printer.log("answer", answer); 

        return (
            uint80(0), // roundId
            answer, // answer
            0, // startedAt
            block.timestamp, // updatedAt
            uint80(0) // answeredInRound
        );
    }
    
    function decimals() public view returns(uint8) {
        return decimalsOracle_;
    }

    function calcPrice(uint256 sqrtPriceX96) public view returns(uint256) {
        uint256 numerator1 = 10**decimalsDelta; 
        uint256 numerator2 = uint256(sqrtPriceX96) *uint256(sqrtPriceX96);  

        uint256 price;
        if (underlyingAsset < underlyingAssetUsd) {
            price = Math.mulDiv(numerator1, numerator2, X192);
        } else {
            price = Math.mulDiv(numerator1, X192, numerator2);
        }
        return price;
    }

}
