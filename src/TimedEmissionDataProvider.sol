// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id} from "morpho-blue/interfaces/IMorpho.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";

import {Multicall} from "openzeppelin/utils/Multicall.sol";

/// @notice A time-bounded rewards emission.
struct TimedRewardsEmission {
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

contract TimedEmissionDataProvider is Multicall {
    /// @notice Returns the time-bounded rewards emission for the given timedRewardsEmissionsId.
    /// Where timedRewardsEmissionsId = keccak256(abi.encode(msg.sender, urd, rewardToken, market)).
    mapping(bytes32 timedRewardsEmissionsId => TimedRewardsEmission) public timedRewardsEmissions;

    /// @notice Emitted when the timed rewards emission is set.
    event TimedRewardsEmissionSet(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        TimedRewardsEmission timedRewardsEmission
    );

    /// @notice Sets the time-bounded rewards emission.
    /// @param rewardToken The reward token of the emission.
    /// @param urd The URD distributing the rewards.
    /// @param market The id of market on which rewards are distributed.
    /// @param timedRewardsEmission The time-bounded rewards emission to set.
    function setTimedRewardsEmission(
        address rewardToken,
        address urd,
        Id market,
        TimedRewardsEmission calldata timedRewardsEmission
    ) public {
        bytes32 timedRewardsEmissionId = keccak256(abi.encode(msg.sender, urd, rewardToken, market));

        require(timedRewardsEmission.startTimestamp >= block.timestamp, ErrorsLib.START_TIMESTAMP_IN_THE_PAST);

        require(
            timedRewardsEmission.endTimestamp > timedRewardsEmission.startTimestamp, ErrorsLib.END_TIMESTAMP_TOO_EARLY
        );

        require(
            timedRewardsEmissions[timedRewardsEmissionId].startTimestamp == 0, ErrorsLib.REWARDS_EMISSION_ALREADY_SET
        );

        timedRewardsEmissions[timedRewardsEmissionId] = timedRewardsEmission;

        emit TimedRewardsEmissionSet(rewardToken, market, msg.sender, urd, timedRewardsEmission);
    }
}
