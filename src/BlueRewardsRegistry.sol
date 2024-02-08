// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id} from "morpho-blue/interfaces/IMorpho.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {Math} from "../lib/morpho-utils/src/math/Math.sol";
import {SafeTransferLib, ERC20} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import {Multicall} from "openzeppelin/utils/Multicall.sol";

/// @notice A time-bounded rewards distribution commitment.
struct RewardsCommitment {
    /// @notice The number of reward tokens distributed per year on the supply side (in the reward token decimals).
    uint256 supplyRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the borrow side (in the reward token decimals).
    uint256 borrowRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the collateral side (in the reward token decimals).
    uint256 collateralRewardTokensPerYear;
    /// @notice The timestamp at which the distribution of rewards starts.
    uint256 startTimestamp;
    /// @notice The timestamp at which the distribution of rewards ends.
    uint256 endTimestamp;
}

contract BlueRewardsRegistry is Multicall {
    using SafeTransferLib for ERC20;

    uint256 public constant MAX_COMMITMENTS_WITH_SAME_ID = 100;

    /// @notice Returns the time-bounded rewards distribution commitments for a given commitmentId.
    /// Where commitmentId = keccak256(abi.encode(msg.sender, urd, rewardToken, market)).
    mapping(bytes32 commitmentId => RewardsCommitment[MAX_COMMITMENTS_WITH_SAME_ID]) public rewardsCommitments;

    /// @notice Emitted when the rewards commitment is registered.
    event RewardsCommitmentRegistered(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        RewardsCommitment commitment
    );

    /// @notice Registers the time-bounded rewards distribution commitment.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the distribution.
    /// @param market The id of market on which rewards are committed to be distributed.
    /// @param commitment The time-bounded rewards distribution commitment.
    function register(address urd, address rewardToken, Id market, RewardsCommitment calldata commitment) public {
        bytes32 commitmentId = _computeCommitmentId(msg.sender, urd, rewardToken, market);

        require(commitment.startTimestamp >= block.timestamp, ErrorsLib.START_TIMESTAMP_OUTDATED);

        require(commitment.endTimestamp > commitment.startTimestamp, ErrorsLib.END_TIMESTAMP_INVALID);

        uint256 amount = commitment.supplyRewardTokensPerYear + commitment.borrowRewardTokensPerYear
            + commitment.collateralRewardTokensPerYear;
        require(amount <= ERC20(rewardToken).balanceOf(msg.sender), ErrorsLib.COMMITMENT_INVALID_AMOUNTS);
        require(amount != 0, ErrorsLib.ZERO_AMOUNT);

        uint256 length = rewardsCommitments[commitmentId].length;
        for (uint256 i = 0; i < length; i++) {
            // if the commitment is already registered and the end timestamp is in the past
            // then update the commitment
            // in case of an empty commitment, the end timestamp is 0 so this condition is always true
            if (rewardsCommitments[commitmentId][i].endTimestamp < block.timestamp) {
                rewardsCommitments[commitmentId][i] = commitment;

                // transfer the reward tokens from the sender to this contract
                ERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amount);

                // transfer the reward tokens from this contract to the URD
                ERC20(rewardToken).safeTransfer(urd, amount);

                emit RewardsCommitmentRegistered(rewardToken, market, msg.sender, urd, commitment);
                return;
            }
        }

        revert(ErrorsLib.MAX_COMMITMENTS_WITH_SAME_ID_EXCEEDED);
    }

    /// @notice Returns the time-bounded rewards distribution commitments for a given commitmentId.
    /// Where commitmentId = keccak256(abi.encode(caller, urd, rewardToken, market)).
    /// @param caller The caller of the `register` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the distribution commitment.
    /// @param market The id of market on which rewards are committed to be distributed.
    function getCommitments(address caller, address urd, address rewardToken, Id market)
        public
        view
        returns (RewardsCommitment[MAX_COMMITMENTS_WITH_SAME_ID] memory)
    {
        return rewardsCommitments[_computeCommitmentId(caller, urd, rewardToken, market)];
    }

    /// @notice Computes the time-bounded rewards commitment id.
    /// @param caller The caller of the `setTimedRewardsEmission` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the distribution.
    /// @param market The id of market on which rewards are distributed.
    function _computeCommitmentId(address caller, address urd, address rewardToken, Id market)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(caller, urd, rewardToken, market));
    }
}
