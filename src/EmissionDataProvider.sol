// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id} from "morpho-blue/interfaces/IMorpho.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";

import {Multicall} from "openzeppelin/utils/Multicall.sol";

struct RewardsEmission {
    /// @notice The number of reward tokens distributed per year on the supply side (in the reward token decimals).
    uint256 supplyRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the borrow side (in the reward token decimals).
    uint256 borrowRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the collateral side (in the reward token decimals).
    uint256 collateralRewardTokensPerYear;
    /// @notice The timestamp at which the reward emission starts.
    uint256 startTimestamp;
    /// @notice The timestamp at which the reward emission ends.
    uint256 endTimestamp;
}

contract EmissionDataProvider is Multicall {
    /// @notice Returns the rewards emission for the given rewardEmissionId.
    /// Where rewardEmissionId = keccak256(abi.encode(msg.sender, urd, rewardToken, market)).
    mapping(bytes32 rewardEmissionId => RewardsEmission) public rewardsEmissions;

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
        bytes32 rewardEmissionId = keccak256(abi.encode(msg.sender, urd, rewardToken, market));

        require(rewardsEmission.startTimestamp >= block.timestamp, ErrorsLib.START_TIMESTAMP_IN_THE_PAST);

        require(rewardsEmission.endTimestamp > rewardsEmission.startTimestamp, ErrorsLib.END_TIMESTAMP_TOO_EARLY);

        require(rewardsEmissions[rewardEmissionId].startTimestamp == 0, ErrorsLib.REWARDS_EMISSION_ALREADY_SET);

        rewardsEmissions[rewardEmissionId] = rewardsEmission;

        emit RewardsEmissionSet(rewardToken, market, msg.sender, urd, rewardsEmission);
    }
}
