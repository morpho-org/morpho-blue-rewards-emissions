// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

struct RewardsEmission {

    /// @notice the date at which the emission starts
    uint256 startAt;

    /// @notice the date at which the emission ends
    /// @dev if 0, the emission is considered to not have end date for now.
    uint256 endAt;

    /// @notice the amount of tokens to be emitted per year (365 days)
    uint256 ratePerYear;
}

contract EmissionDataProvider is Ownable {


    /// @notice rewards program id -> token -> market -> RewardsEmission mapping
    mapping(uint256 => mapping(address => mapping(bytes32 => RewardsEmission))) public rewardsEmissions;

    event RewardsEmissionSet(uint256 indexed id, address indexed token, bytes32 indexed market, RewardsEmission rewardsEmission);

    constructor() Ownable() {}

    function setRewardsEmission(uint256 id, address token, bytes32[] memory markets, RewardsEmission[] memory emissions) public onlyOwner {
        require(markets.length == emissions.length, "EmissionDataProvider: markets and emissions length mismatch");

        for (uint256 i = 0; i < markets.length; i++) {
            require(emissions[i].startAt >= block.timestamp, "EmissionDataProvider: emission startAt must be greater than current timestamp");
            require(emissions[i].endAt == 0 || emissions[i].endAt > emissions[i].startAt, "EmissionDataProvider: emission endAt must be greater than startAt");

            rewardsEmissions[id][token][markets[i]] = emissions[i];

            emit RewardsEmissionSet(id, token, markets[i], emissions[i]);
        }
    }


}
