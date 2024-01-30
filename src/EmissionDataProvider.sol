// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id} from "morpho-blue/interfaces/IMorpho.sol";

import {Multicall} from "openzeppelin/utils/Multicall.sol";

struct RewardsEmission {
    /// @notice The number of reward tokens distributed per year on the supply side (in the reward token decimals).
    uint256 supplyRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the borrow side (in the reward token decimals).
    uint256 borrowRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the collateral side (in the reward token decimals).
    uint256 collateralRewardTokensPerYear;
}

contract EmissionDataProvider is Multicall {
    /// @notice Returns the rewards emission. sender -> urd -> token -> market -> rewardsEmission.
    mapping(
        address sender
            => mapping(address urd => mapping(address rewardToken => mapping(Id marketId => RewardsEmission)))
    ) public rewardsEmissions;

    /// @notice Emitted when the rewards emission is set.
    event RewardsEmissionSet(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        RewardsEmission rewardsEmission
    );

    /// @notice Sets the rewards emission.
    /// @param rewardToken The reward token of the emission.
    /// @param urd The URD distributing the rewards.
    /// @param market The id of market on which rewards are distributed.
    /// @param rewardsEmission The rewards emission to set.
    function setRewardsEmission(address rewardToken, address urd, Id market, RewardsEmission calldata rewardsEmission)
        public
    {
        rewardsEmissions[msg.sender][urd][rewardToken][market] = rewardsEmission;

        emit RewardsEmissionSet(rewardToken, market, msg.sender, urd, rewardsEmission);
    }
}
