// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/UniversalRewardsRegistry.sol";
import {MockERC20} from "lib/solmate/src/test/utils/mocks/MockERC20.sol";

contract UniversalRewardsRegistryTest is Test {
    UniversalRewardsRegistry registry;
    address internal USER = makeAddr("User");

    bytes[] internal data;

    event RewardsRegistered(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        RewardsCommitment commitment
    );

    function setUp() public {
        registry = new UniversalRewardsRegistry();
    }

    function testCommit(
        address urd,
        Id market,
        RewardsCommitment calldata commitment
    ) public {
        vm.assume(commitment.startTimestamp >= block.timestamp);
        vm.assume(commitment.endTimestamp > commitment.startTimestamp);
        vm.assume(
            commitment.supplyRewardTokensPerYear > 0 ||
                commitment.borrowRewardTokensPerYear > 0 ||
                commitment.collateralRewardTokensPerYear > 0
        );
        // realistic assumption, the three fields are less than 2^256 combined
        vm.assume(
            commitment.supplyRewardTokensPerYear < (type(uint256).max / 3) &&
                commitment.borrowRewardTokensPerYear <
                (type(uint256).max / 3) &&
                commitment.collateralRewardTokensPerYear <
                (type(uint256).max / 3)
        );

        uint256 amount = commitment.supplyRewardTokensPerYear +
            commitment.borrowRewardTokensPerYear +
            commitment.collateralRewardTokensPerYear;
        // create and mint ERC20
        MockERC20 token = new MockERC20("mock", "MOCK", 18);
        token.mint(USER, amount);

        // approve ERC20
        vm.prank(USER);
        ERC20(token).approve(address(registry), type(uint256).max);

        data.push(
            abi.encodeCall(
                UniversalRewardsRegistry.erc20TransferFrom,
                (address(token), amount)
            )
        );
        data.push(
            abi.encodeCall(
                UniversalRewardsRegistry.commit,
                (urd, address(token), market, commitment)
            )
        );

        vm.expectEmit();
        emit RewardsRegistered(address(token), market, USER, urd, commitment);
        vm.prank(USER);
        registry.multicall(data);

        RewardsCommitment[100] memory registeredCommitments = registry
            .getCommitments(USER, urd, address(token), market);

        assertEq(
            commitment.supplyRewardTokensPerYear,
            registeredCommitments[0].supplyRewardTokensPerYear
        );
        assertEq(
            commitment.borrowRewardTokensPerYear,
            registeredCommitments[0].borrowRewardTokensPerYear
        );
        assertEq(
            commitment.collateralRewardTokensPerYear,
            registeredCommitments[0].collateralRewardTokensPerYear
        );
        assertEq(
            commitment.startTimestamp,
            registeredCommitments[0].startTimestamp
        );
        assertEq(
            commitment.endTimestamp,
            registeredCommitments[0].endTimestamp
        );
    }

    //     function testSetTimedRewardsEmissionShouldRevertWhenStartTimestampIsInThePast(
    //         address caller,
    //         RewardsCommitment calldata commitment
    //     ) public {
    //         // The start timestamp is set in the past.
    //         vm.assume(emission.startTimestamp < block.timestamp);
    //         vm.assume(emission.endTimestamp > emission.startTimestamp);

    //         vm.prank(caller);
    //         vm.expectRevert(bytes(ErrorsLib.START_TIMESTAMP_OUTDATED));
    //         dataProvider.setTimedRewardsEmission(
    //             address(0),
    //             address(0),
    //             Id.wrap(bytes32(uint256(0))),
    //             emission
    //         );
    //     }

    //     function testSetTimedRewardsEmissionShouldRevertWhenEndTimestampIsBeforeStartTimestamp(
    //         address caller,
    //         RewardsCommitment calldata commitment
    //     ) public {
    //         vm.assume(emission.startTimestamp >= block.timestamp);
    //         // The end timestamp is set before the start timestamp.
    //         vm.assume(emission.endTimestamp < emission.startTimestamp);

    //         vm.prank(caller);
    //         vm.expectRevert(bytes(ErrorsLib.END_TIMESTAMP_INVALID));
    //         dataProvider.setTimedRewardsEmission(
    //             address(0),
    //             address(0),
    //             Id.wrap(bytes32(uint256(0))),
    //             emission
    //         );
    //     }

    //     function testSetRewardsShouldRevertWhenSameCallerWantsToUpdateAlreadySetEmission(
    //         address caller,
    //         address token,
    //         address urd,
    //         Id market,
    //         RewardsCommitment calldata commitment
    //     ) public {
    //         vm.assume(emission.startTimestamp >= block.timestamp);
    //         vm.assume(emission.endTimestamp > emission.startTimestamp);

    //         vm.prank(caller);
    //         dataProvider.setTimedRewardsEmission(urd, token, market, emission);

    //         TimedRewardsEmission memory newEmission = TimedRewardsEmission(
    //             1,
    //             1,
    //             1,
    //             block.timestamp + 1,
    //             block.timestamp + 2
    //         );

    //         vm.prank(caller);
    //         vm.expectRevert(bytes(ErrorsLib.REWARDS_EMISSION_ALREADY_SET));
    //         dataProvider.setTimedRewardsEmission(urd, token, market, newEmission);
    //     }

    //     function testMulticall() public {
    //         data.push(
    //             abi.encodeCall(
    //                 TimedEmissionDataProvider.setTimedRewardsEmission,
    //                 (
    //                     address(0),
    //                     address(0),
    //                     Id.wrap(bytes32(uint256(1))),
    //                     TimedRewardsEmission(
    //                         1,
    //                         1,
    //                         1,
    //                         block.timestamp,
    //                         block.timestamp + 1
    //                     )
    //                 )
    //             )
    //         );
    //         data.push(
    //             abi.encodeCall(
    //                 TimedEmissionDataProvider.setTimedRewardsEmission,
    //                 (
    //                     address(1),
    //                     address(1),
    //                     Id.wrap(bytes32(uint256(2))),
    //                     TimedRewardsEmission(
    //                         2,
    //                         2,
    //                         2,
    //                         block.timestamp + 1,
    //                         block.timestamp + 2
    //                     )
    //                 )
    //             )
    //         );
    //         data.push(
    //             abi.encodeCall(
    //                 TimedEmissionDataProvider.setTimedRewardsEmission,
    //                 (
    //                     address(2),
    //                     address(2),
    //                     Id.wrap(bytes32(uint256(3))),
    //                     TimedRewardsEmission(
    //                         3,
    //                         3,
    //                         3,
    //                         block.timestamp + 2,
    //                         block.timestamp + 3
    //                     )
    //                 )
    //             )
    //         );

    //         dataProvider.multicall(data);

    //         TimedRewardsEmission memory createdEmission0 = dataProvider
    //             .getTimedRewardsEmissions(
    //                 address(this),
    //                 address(0),
    //                 address(0),
    //                 Id.wrap(bytes32(uint256(1)))
    //             );
    //         TimedRewardsEmission memory createdEmission1 = dataProvider
    //             .getTimedRewardsEmissions(
    //                 address(this),
    //                 address(1),
    //                 address(1),
    //                 Id.wrap(bytes32(uint256(2)))
    //             );
    //         TimedRewardsEmission memory createdEmission2 = dataProvider
    //             .getTimedRewardsEmissions(
    //                 address(this),
    //                 address(2),
    //                 address(2),
    //                 Id.wrap(bytes32(uint256(3)))
    //             );

    //         assertEq(createdEmission0.supplyRewardTokensPerYear, 1);
    //         assertEq(createdEmission0.borrowRewardTokensPerYear, 1);
    //         assertEq(createdEmission0.collateralRewardTokensPerYear, 1);
    //         assertEq(createdEmission0.startTimestamp, block.timestamp);
    //         assertEq(createdEmission0.endTimestamp, block.timestamp + 1);
    //         assertEq(createdEmission1.supplyRewardTokensPerYear, 2);
    //         assertEq(createdEmission1.borrowRewardTokensPerYear, 2);
    //         assertEq(createdEmission1.collateralRewardTokensPerYear, 2);
    //         assertEq(createdEmission1.startTimestamp, block.timestamp + 1);
    //         assertEq(createdEmission1.endTimestamp, block.timestamp + 2);
    //         assertEq(createdEmission2.supplyRewardTokensPerYear, 3);
    //         assertEq(createdEmission2.borrowRewardTokensPerYear, 3);
    //         assertEq(createdEmission2.collateralRewardTokensPerYear, 3);
    //         assertEq(createdEmission2.startTimestamp, block.timestamp + 2);
    //         assertEq(createdEmission2.endTimestamp, block.timestamp + 3);
    //     }
}
