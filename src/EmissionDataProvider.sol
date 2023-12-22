// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Multicall} from "openzeppelin/utils/Multicall.sol";
import {Id} from "morpho-blue/interfaces/IMorpho.sol";

struct RewardsEmission {
    uint256 supplyRatePerYear;
    uint256 borrowRatePerYear;
    uint256 collateralRatePerYear;
}

contract EmissionDataProvider is Multicall {
    /// @notice reward token -> market -> RewardsEmission mapping
    mapping(
        address sender
            => mapping(address urd => mapping(address rewardToken => mapping(Id marketId => RewardsEmission)))
    ) public rewardsEmissions;

    event RewardsEmissionSet(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        RewardsEmission rewardsEmission
    );

    function setRewardsEmission(address token, address urd, Id market, RewardsEmission calldata rewardsEmission)
        public
    {
        rewardsEmissions[msg.sender][urd][token][market] = rewardsEmission;

        emit RewardsEmissionSet(token, market, msg.sender, urd, rewardsEmission);
    }
}
