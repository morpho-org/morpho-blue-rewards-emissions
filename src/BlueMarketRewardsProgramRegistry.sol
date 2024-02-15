// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id} from "morpho-blue/interfaces/IMorpho.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";

import {Multicall} from "openzeppelin/utils/Multicall.sol";

/// @notice A time-bounded rewards program on a market.
struct MarketRewardsProgram {
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

contract BlueMarketRewardsProgramRegistry is Multicall {
    uint256 public constant MAX_PROGRAMS_WITH_SAME_ID = 100;

    /// @notice Returns the time-bounded market rewards programs for a given id.
    /// Where id = keccak256(abi.encode(msg.sender, urd, rewardToken, market)).
    mapping(bytes32 id => MarketRewardsProgram[MAX_PROGRAMS_WITH_SAME_ID]) public programs;

    /// @notice Emitted when a rewards program for a market is registered.
    event ProgramRegistered(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        MarketRewardsProgram program
    );

    /// @notice Registers the time-bounded market rewards program.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of market on which rewards are programmed to be distributed.
    /// @param program The time-bounded rewards program.
    function register(address urd, address rewardToken, Id market, MarketRewardsProgram calldata program) public {
        bytes32 programId = _id(msg.sender, urd, rewardToken, market);

        require(program.startTimestamp >= block.timestamp, ErrorsLib.START_TIMESTAMP_OUTDATED);

        require(program.endTimestamp > program.startTimestamp, ErrorsLib.END_TIMESTAMP_INVALID);

        uint256 length = programs[programId].length;
        for (uint256 i = 0; i < length; i++) {
            MarketRewardsProgram memory existingProgram = programs[programId][i];

            if (
                existingProgram.supplyRewardTokensPerYear == program.supplyRewardTokensPerYear
                    && existingProgram.borrowRewardTokensPerYear == program.borrowRewardTokensPerYear
                    && existingProgram.collateralRewardTokensPerYear == program.collateralRewardTokensPerYear
                    && existingProgram.startTimestamp == program.startTimestamp
                    && existingProgram.endTimestamp == program.endTimestamp
            ) {
                revert(ErrorsLib.PROGRAM_ALREADY_SET);
            }

            // if the program is not active anymore, we can override it
            // in case of an empty program, the end timestamp is 0 so this condition is always true
            if (existingProgram.endTimestamp < block.timestamp) {
                programs[programId][i] = program;

                emit ProgramRegistered(rewardToken, market, msg.sender, urd, program);
                return;
            }
        }

        revert(ErrorsLib.MAX_PROGRAMS_WITH_SAME_ID_EXCEEDED);
    }

    /// @notice Returns the time-bounded market rewards programs for a given id.
    /// Where id = keccak256(abi.encode(caller, urd, rewardToken, market)).
    /// @param caller The caller of the `register` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of Blue market on which rewards are programmed to be distributed.
    function getPrograms(address caller, address urd, address rewardToken, Id market)
        public
        view
        returns (MarketRewardsProgram[MAX_PROGRAMS_WITH_SAME_ID] memory)
    {
        return programs[_id(caller, urd, rewardToken, market)];
    }

    /// @notice Computes the time-bounded market rewards program id.
    /// @param caller The caller of the `register` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of Blue market on which rewards are programmed to be distributed..
    function _id(address caller, address urd, address rewardToken, Id market) internal pure returns (bytes32) {
        return keccak256(abi.encode(caller, urd, rewardToken, market));
    }
}
