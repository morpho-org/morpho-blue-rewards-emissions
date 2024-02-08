// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id} from "morpho-blue/interfaces/IMorpho.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {Math} from "../lib/morpho-utils/src/math/Math.sol";
import {SafeTransferLib, ERC20} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import {Multicall} from "openzeppelin/utils/Multicall.sol";

/// @notice A time-bounded rewards program.
struct RewardsProgram {
    /// @notice The number of reward tokens distributed per year on the supply side (in the reward token decimals).
    uint256 supplyRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the borrow side (in the reward token decimals).
    uint256 borrowRewardTokensPerYear;
    /// @notice The number of reward tokens distributed per year on the collateral side (in the reward token decimals).
    uint256 collateralRewardTokensPerYear;
    /// @notice The timestamp at which the rewards program starts.
    uint256 startTimestamp;
    /// @notice The timestamp at which the rewards program ends.
    uint256 endTimestamp;
}

contract BlueRewardsProgramRegistry is Multicall {
    using SafeTransferLib for ERC20;

    uint256 public constant MAX_COMMITMENTS_WITH_SAME_ID = 100;

    /// @notice Returns the time-bounded rewards program for a given id.
    /// Where id = keccak256(abi.encode(msg.sender, urd, rewardToken, market)).
    mapping(bytes32 programId => RewardsProgram[MAX_COMMITMENTS_WITH_SAME_ID]) public rewardsPrograms;

    /// @notice Emitted when the rewards program is registered.
    event RewardsProgramRegistered(
        address indexed rewardToken, Id indexed market, address indexed sender, address urd, RewardsProgram program
    );

    /// @notice Registers the time-bounded rewards program.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of market on which rewards are programmed to be distributed.
    /// @param program The time-bounded rewards program.
    function register(address urd, address rewardToken, Id market, RewardsProgram calldata program) public {
        bytes32 programId = _computeProgramId(msg.sender, urd, rewardToken, market);

        require(program.startTimestamp >= block.timestamp, ErrorsLib.START_TIMESTAMP_OUTDATED);

        require(program.endTimestamp > program.startTimestamp, ErrorsLib.END_TIMESTAMP_INVALID);

        uint256 amount = program.supplyRewardTokensPerYear + program.borrowRewardTokensPerYear
            + program.collateralRewardTokensPerYear;
        require(amount <= ERC20(rewardToken).balanceOf(msg.sender), ErrorsLib.PROGRAM_INVALID_AMOUNTS);
        require(amount != 0, ErrorsLib.ZERO_AMOUNT);

        uint256 length = rewardsPrograms[programId].length;
        for (uint256 i = 0; i < length; i++) {
            RewardsProgram memory existingProgram = rewardsPrograms[programId][i];

            if (
                existingProgram.supplyRewardTokensPerYear == program.supplyRewardTokensPerYear
                    && existingProgram.borrowRewardTokensPerYear == program.borrowRewardTokensPerYear
                    && existingProgram.collateralRewardTokensPerYear == program.collateralRewardTokensPerYear
                    && existingProgram.startTimestamp == program.startTimestamp
                    && existingProgram.endTimestamp == program.endTimestamp
            ) {
                revert(ErrorsLib.PROGRAM_ALREADY_SET);
            }

            // if the program is already registered and the end timestamp is in the past
            // then update the program
            // in case of an empty program, the end timestamp is 0 so this condition is always true
            if (existingProgram.endTimestamp < block.timestamp) {
                rewardsPrograms[programId][i] = program;

                // transfer the reward tokens from the sender to this contract
                ERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amount);

                // transfer the reward tokens from this contract to the URD
                ERC20(rewardToken).safeTransfer(urd, amount);

                emit RewardsProgramRegistered(rewardToken, market, msg.sender, urd, program);
                return;
            }
        }

        revert(ErrorsLib.MAX_PROGRAMS_WITH_SAME_ID_EXCEEDED);
    }

    /// @notice Returns the time-bounded rewards programs for a given programId.
    /// Where programId = keccak256(abi.encode(caller, urd, rewardToken, market)).
    /// @param caller The caller of the `register` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of Blue market on which rewards are programmed to be distributed.
    function getPrograms(address caller, address urd, address rewardToken, Id market)
        public
        view
        returns (RewardsProgram[MAX_COMMITMENTS_WITH_SAME_ID] memory)
    {
        return rewardsPrograms[_computeProgramId(caller, urd, rewardToken, market)];
    }

    /// @notice Computes the time-bounded rewards program id.
    /// @param caller The caller of the `register` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of Blue market on which rewards are programmed to be distributed..
    function _computeProgramId(address caller, address urd, address rewardToken, Id market)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(caller, urd, rewardToken, market));
    }
}
