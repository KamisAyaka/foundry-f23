// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author Firefly
 * @notice This library is to check the Chainlink Oracle prices
 * If a price is stale, the function will revert, and render the DSCEngine unusable. - this is by design
 * we want the DSCEngine to freeze if prices are stale.
 *
 * The solution for this problem is to have a stale period, after which the oracle needs to be updated.
 */

library OracleLib {
    error OracleLib__StalePrice();
    uint256 private constant TIMEOUT = 3 hours;

    function stableCheckLatestRoundData(
        AggregatorV3Interface priceFeed
    ) public view returns (uint80, int256, uint256, uint256, uint80) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        uint256 secondesSince = block.timestamp - updatedAt;
        if (secondesSince > TIMEOUT) {
            revert OracleLib__StalePrice();
        }
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
