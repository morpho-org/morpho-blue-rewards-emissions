// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Id as MarketId} from "morpho-blue/interfaces/IMorpho.sol";
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
    uint256 start;
    /// @notice The timestamp at which the rewards program ends.
    uint256 end;
}

/// @title MarketRewardsProgramRegistry
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice A registry of time-bounded market rewards programs.
contract MarketRewardsProgramRegistry is Multicall {
    uint256 public constant MAX_PROGRAMS_WITH_SAME_ID = 30;

    /// @notice Returns a set of time-bounded market rewards programs for a given id.
    /// Where id = keccak256(abi.encode(owner, urd, rewardToken, market)).
    /// The set can contain up to 30 programs with the same id.
    /// A program already registered in the set cannot be updated or deleted.
    mapping(bytes32 id => MarketRewardsProgram[]) public programs;

    /// @notice Emitted when a rewards program for a market is registered.
    event ProgramRegistered(
        address indexed rewardToken,
        MarketId indexed market,
        address indexed sender,
        address urd,
        MarketRewardsProgram program
    );

    /// @notice Registers the time-bounded market rewards program.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of market on which rewards are programmed to be distributed.
    /// @param program The time-bounded rewards program.
    function register(address urd, address rewardToken, MarketId market, MarketRewardsProgram calldata program)
        public
    {
        require(program.start >= block.timestamp, ErrorsLib.START_TIMESTAMP_OUTDATED);

        require(program.end > program.start, ErrorsLib.END_TIMESTAMP_INVALID);

        bytes32 id = _id(msg.sender, urd, rewardToken, market);

        if (getNumberOfProgramsForId(id) == MAX_PROGRAMS_WITH_SAME_ID) {
            revert(ErrorsLib.MAX_PROGRAMS_WITH_SAME_ID_EXCEEDED);
        }

        programs[id].push(program);

        emit ProgramRegistered(rewardToken, market, msg.sender, urd, program);
    }

    /// @notice Returns the set of time-bounded market rewards programs for a given id.
    /// Where id = keccak256(abi.encode(caller, urd, rewardToken, market)).
    /// @param caller The caller of the `register` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of Blue market on which rewards are programmed to be distributed.
    function getPrograms(address caller, address urd, address rewardToken, MarketId market)
        public
        view
        returns (MarketRewardsProgram[] memory)
    {
        return programs[_id(caller, urd, rewardToken, market)];
    }

    /// @notice Returns the number of time-bounded market rewards programs with the same id.
    /// Where id = keccak256(abi.encode(caller, urd, rewardToken, market)).
    /// @param id The id of the time-bounded market rewards programs.
    function getNumberOfProgramsForId(bytes32 id) public view returns (uint256) {
        return programs[id].length;
    }

    /// @notice Computes the time-bounded market rewards program id.
    /// @param caller The caller of the `register` function.
    /// @param urd The URD that should redistribute the rewards.
    /// @param rewardToken The reward token of the program.
    /// @param market The id of Blue market on which rewards are programmed to be distributed.
    function _id(address caller, address urd, address rewardToken, MarketId market) internal pure returns (bytes32) {
        return keccak256(abi.encode(caller, urd, rewardToken, market));
    }
}
