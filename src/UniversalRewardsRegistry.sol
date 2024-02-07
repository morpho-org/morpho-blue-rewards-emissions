// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id} from "morpho-blue/interfaces/IMorpho.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {ErrorsLib as ErrorsLibBundlers} from "morpho-blue-bundlers/libraries/ErrorsLib.sol";
import {Math} from "../lib/morpho-utils/src/math/Math.sol";
import {SafeTransferLib, ERC20} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import {Multicall} from "openzeppelin/utils/Multicall.sol";
import {BaseBundler} from "morpho-blue-bundlers/BaseBundler.sol";

/// @notice A time-bounded registered rewards distribution.
struct RewardsCommitment {
    /// @notice The number of reward tokens distributed per year on the supply side (in the reward token decimals).
    uint256 supplyRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the borrow side (in the reward token decimals).
    uint256 borrowRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the collateral side (in the reward token decimals).
    uint256 collateralRewardTokensPerYear;
    /// @notice The timestamp at which the reward distribution starts.
    uint256 startTimestamp;
    /// @notice The timestamp at which the reward distribution ends.
    uint256 endTimestamp;
}

contract UniversalRewardsRegistry is BaseBundler {
    using SafeTransferLib for ERC20;

    uint256 public constant MAX_COMMITMENTS_WITH_SAME_ID = 100;

    /// @notice Returns the time-bounded rewards distribution for the given timedRewardsEmissionId.
    /// Where timedRewardsEmissionId = keccak256(abi.encode(_initiator, urd, rewardToken, market)).
    mapping(bytes32 registrationId => RewardsCommitment[MAX_COMMITMENTS_WITH_SAME_ID])
        public rewardsCommitments;

    /// @notice Emitted when the timed rewards distribution is set.
    event RewardsRegistered(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        RewardsCommitment commitment
    );

    /// @notice Sets the time-bounded rewards distribution.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the distribution.
    /// @param market The id of market on which rewards are distributed.
    /// @param commitment The time-bounded rewards distribution to commit.
    function commit(
        address urd,
        address rewardToken,
        Id market,
        RewardsCommitment calldata commitment
    ) public protected {
        address _initiator = initiator();
        bytes32 commitmentId = _computeCommitmentId(
            _initiator,
            urd,
            rewardToken,
            market
        );

        require(
            commitment.startTimestamp >= block.timestamp,
            ErrorsLib.START_TIMESTAMP_OUTDATED
        );

        require(
            commitment.endTimestamp > commitment.startTimestamp,
            ErrorsLib.END_TIMESTAMP_INVALID
        );

        uint256 amount = commitment.supplyRewardTokensPerYear +
            commitment.borrowRewardTokensPerYear +
            commitment.collateralRewardTokensPerYear;
        require(
            amount == ERC20(rewardToken).balanceOf(address(this)),
            ErrorsLib.COMMITMENT_INVALID_AMOUNTS
        );

        uint256 length = rewardsCommitments[commitmentId].length;
        for (uint256 i = 0; i < length; i++) {
            if (rewardsCommitments[commitmentId][i].startTimestamp == 0) {
                rewardsCommitments[commitmentId][i] = commitment;

                ERC20(rewardToken).safeTransfer(urd, amount);

                emit RewardsRegistered(
                    rewardToken,
                    market,
                    _initiator,
                    urd,
                    commitment
                );
                return;
            }
        }

        revert(ErrorsLib.MAX_COMMITMENTS_WITH_SAME_ID_EXCEEDED);
    }

    /// @notice Transfers the given `amount` of `asset` from sender to this contract via ERC20 transferFrom.
    /// @notice User must have given sufficient allowance to the Bundler to spend their tokens.
    /// @param asset The address of the ERC20 token to transfer.
    /// @param amount The amount of `asset` to transfer from the initiator. Capped at the initiator's balance.
    function erc20TransferFrom(
        address asset,
        uint256 amount
    ) external payable protected {
        address _initiator = initiator();
        amount = Math.min(amount, ERC20(asset).balanceOf(_initiator));

        require(amount != 0, ErrorsLibBundlers.ZERO_AMOUNT);

        ERC20(asset).safeTransferFrom(_initiator, address(this), amount);
    }

    /// @notice Returns the time-bounded rewards distribution for the given timedRewardsEmissionId.
    /// Where timedRewardsEmissionId = keccak256(abi.encode(caller, urd, rewardToken, market)).
    /// @param caller The caller of the `setTimedRewardsEmission` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the distribution.
    /// @param market The id of market on which rewards are distributed.
    function getCommitments(
        address caller,
        address urd,
        address rewardToken,
        Id market
    )
        public
        view
        returns (RewardsCommitment[MAX_COMMITMENTS_WITH_SAME_ID] memory)
    {
        return
            rewardsCommitments[
                _computeCommitmentId(caller, urd, rewardToken, market)
            ];
    }

    /// @notice Computes the time-bounded rewards distribution id.
    /// @param caller The caller of the `setTimedRewardsEmission` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the distribution.
    /// @param market The id of market on which rewards are distributed.
    function _computeCommitmentId(
        address caller,
        address urd,
        address rewardToken,
        Id market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(caller, urd, rewardToken, market));
    }
}
