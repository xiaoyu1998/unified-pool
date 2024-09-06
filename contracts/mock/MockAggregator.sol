// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../oracle/IPriceFeed.sol";

// @title MockAggregator
// @dev Mock price feed for testing and testnets
contract MockAggregator is IPriceFeed, Ownable {
   event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
   event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

    uint256 constant public version = 0;

    uint8 public decimals;
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint256 public latestRound;

    mapping(uint256 => int256) public getAnswer;
    mapping(uint256 => uint256) public getTimestamp;
    mapping(uint256 => uint256) private getStartedAt;

    constructor(
        uint8 _decimals,
        int256 _initialAnswer
    ) {
        decimals = _decimals;
        _setAnswer(_initialAnswer);
    }

    function _setAnswer(
       int256 _answer
    ) internal {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;

        emit AnswerUpdated (
            _answer,
            latestRound,
            block.timestamp
        );

        emit NewRound (
            latestRound,
            owner(),
            block.timestamp
        );

    }

    function setAnswer(
       int256 _answer
    ) external  {
        _setAnswer(_answer);
    }

    function updateRoundData(
        uint80 _roundId,
        int256 _answer,
        uint256 _timestamp,
        uint256 _startedAt
    ) external {
        latestRound = _roundId;
        latestAnswer = _answer;
        latestTimestamp = _timestamp;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = _timestamp;
        getStartedAt[latestRound] = _startedAt;

        emit AnswerUpdated (
            _answer,
            _roundId,
            block.timestamp
        );
    }

    function getRoundData(uint80 _roundId)
        external 
        view  
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _roundId,
            getAnswer[_roundId],
            getStartedAt[_roundId],
            getTimestamp[_roundId],
            _roundId
        );
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    function description()
        external
        pure
        returns (string memory)
    {
        return "/mock/MockAggregator.sol";
    }
}
