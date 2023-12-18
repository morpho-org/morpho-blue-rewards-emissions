// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Multicall} from "openzeppelin/utils/Multicall.sol";

struct RewardsEmission {
    uint256 supplyRatePerYear;
    uint256 borrowRatePerYear;
    uint256 collateralRatePerYear;
}

contract EmissionDataProvider is Multicall {
    /// @notice reward token -> market -> RewardsEmission mapping
    mapping(
        address sender
            => mapping(address urd => mapping(address rewardToken => mapping(bytes32 marketId => RewardsEmission)))
    ) public rewardsEmissions;

    event RewardsEmissionSet(
        address indexed rewardToken,
        bytes32 indexed market,
        address indexed sender,
        address urd,
        RewardsEmission rewardsEmission
    );

    constructor() {}

    function setRewardsEmission(address token, address urd, bytes32 market, RewardsEmission calldata rewardsEmission)
        public
    {
        rewardsEmissions[msg.sender][urd][token][market] = rewardsEmission;

        emit RewardsEmissionSet(token, market, msg.sender, urd, rewardsEmission);
    }
}
