// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/TimedEmissionDataProvider.sol";

contract TimedEmissionDataProviderTest is Test {
    TimedEmissionDataProvider dataProvider;

    bytes[] internal data;

    event TimedRewardsEmissionSet(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        TimedRewardsEmission timedRewardsEmissions
    );

    function setUp() public {
        dataProvider = new TimedEmissionDataProvider();
    }

    function testSetTimedRewardsEmission(
        address caller,
        address urd,
        address token,
        Id market,
        TimedRewardsEmission calldata emission
    ) public {
        vm.assume(emission.startTimestamp >= block.timestamp);
        vm.assume(emission.endTimestamp > emission.startTimestamp);

        vm.expectEmit();
        emit TimedRewardsEmissionSet(token, market, caller, urd, emission);
        vm.prank(caller);
        dataProvider.setTimedRewardsEmission(urd, token, market, emission);

        TimedRewardsEmission memory createdEmission = dataProvider.getTimedRewardsEmissions(caller, urd, token, market);

        assertEq(emission.supplyRewardTokensPerYear, createdEmission.supplyRewardTokensPerYear);
        assertEq(emission.borrowRewardTokensPerYear, createdEmission.borrowRewardTokensPerYear);
        assertEq(emission.collateralRewardTokensPerYear, createdEmission.collateralRewardTokensPerYear);
        assertEq(emission.startTimestamp, createdEmission.startTimestamp);
        assertEq(emission.endTimestamp, createdEmission.endTimestamp);
    }

    function testSetTimedRewardsEmissionShouldRevertWhenStartTimestampIsInThePast(
        address caller,
        TimedRewardsEmission calldata emission
    ) public {
        // The start timestamp is set in the past.
        vm.assume(emission.startTimestamp < block.timestamp);
        vm.assume(emission.endTimestamp > emission.startTimestamp);

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.START_TIMESTAMP_OUTDATED));
        dataProvider.setTimedRewardsEmission(address(0), address(0), Id.wrap(bytes32(uint256(0))), emission);
    }

    function testSetTimedRewardsEmissionShouldRevertWhenEndTimestampIsBeforeStartTimestamp(
        address caller,
        TimedRewardsEmission calldata emission
    ) public {
        vm.assume(emission.startTimestamp >= block.timestamp);
        // The end timestamp is set before the start timestamp.
        vm.assume(emission.endTimestamp < emission.startTimestamp);

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.END_TIMESTAMP_INVALID));
        dataProvider.setTimedRewardsEmission(address(0), address(0), Id.wrap(bytes32(uint256(0))), emission);
    }

    function testSetRewardsShouldRevertWhenSameCallerWantsToUpdateAlreadySetEmission(
        address caller,
        address token,
        address urd,
        Id market,
        TimedRewardsEmission calldata emission
    ) public {
        vm.assume(emission.startTimestamp >= block.timestamp);
        vm.assume(emission.endTimestamp > emission.startTimestamp);

        vm.prank(caller);
        dataProvider.setTimedRewardsEmission(urd, token, market, emission);

        TimedRewardsEmission memory newEmission =
            TimedRewardsEmission(1, 1, 1, block.timestamp + 1, block.timestamp + 2);

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.REWARDS_EMISSION_ALREADY_SET));
        dataProvider.setTimedRewardsEmission(urd, token, market, newEmission);
    }

    function testMulticall() public {
        data.push(
            abi.encodeCall(
                TimedEmissionDataProvider.setTimedRewardsEmission,
                (
                    address(0),
                    address(0),
                    Id.wrap(bytes32(uint256(1))),
                    TimedRewardsEmission(1, 1, 1, block.timestamp, block.timestamp + 1)
                )
            )
        );
        data.push(
            abi.encodeCall(
                TimedEmissionDataProvider.setTimedRewardsEmission,
                (
                    address(1),
                    address(1),
                    Id.wrap(bytes32(uint256(2))),
                    TimedRewardsEmission(2, 2, 2, block.timestamp + 1, block.timestamp + 2)
                )
            )
        );
        data.push(
            abi.encodeCall(
                TimedEmissionDataProvider.setTimedRewardsEmission,
                (
                    address(2),
                    address(2),
                    Id.wrap(bytes32(uint256(3))),
                    TimedRewardsEmission(3, 3, 3, block.timestamp + 2, block.timestamp + 3)
                )
            )
        );

        dataProvider.multicall(data);

        TimedRewardsEmission memory createdEmission0 =
            dataProvider.getTimedRewardsEmissions(address(this), address(0), address(0), Id.wrap(bytes32(uint256(1))));
        TimedRewardsEmission memory createdEmission1 =
            dataProvider.getTimedRewardsEmissions(address(this), address(1), address(1), Id.wrap(bytes32(uint256(2))));
        TimedRewardsEmission memory createdEmission2 =
            dataProvider.getTimedRewardsEmissions(address(this), address(2), address(2), Id.wrap(bytes32(uint256(3))));

        assertEq(createdEmission0.supplyRewardTokensPerYear, 1);
        assertEq(createdEmission0.borrowRewardTokensPerYear, 1);
        assertEq(createdEmission0.collateralRewardTokensPerYear, 1);
        assertEq(createdEmission0.startTimestamp, block.timestamp);
        assertEq(createdEmission0.endTimestamp, block.timestamp + 1);
        assertEq(createdEmission1.supplyRewardTokensPerYear, 2);
        assertEq(createdEmission1.borrowRewardTokensPerYear, 2);
        assertEq(createdEmission1.collateralRewardTokensPerYear, 2);
        assertEq(createdEmission1.startTimestamp, block.timestamp + 1);
        assertEq(createdEmission1.endTimestamp, block.timestamp + 2);
        assertEq(createdEmission2.supplyRewardTokensPerYear, 3);
        assertEq(createdEmission2.borrowRewardTokensPerYear, 3);
        assertEq(createdEmission2.collateralRewardTokensPerYear, 3);
        assertEq(createdEmission2.startTimestamp, block.timestamp + 2);
        assertEq(createdEmission2.endTimestamp, block.timestamp + 3);
    }
}
