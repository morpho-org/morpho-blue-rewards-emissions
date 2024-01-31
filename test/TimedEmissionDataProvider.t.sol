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

        (
            uint256 supplyRewardTokensPerYear,
            uint256 borrowRewardTokensPerYear,
            uint256 collateralRewardTokensPerYear,
            uint256 startTimestamp,
            uint256 endTimestamp
        ) = dataProvider.timedRewardsEmissions(computeTimedRewardsEmissionId(caller, urd, token, market));

        assertEq(emission.supplyRewardTokensPerYear, supplyRewardTokensPerYear);
        assertEq(emission.borrowRewardTokensPerYear, borrowRewardTokensPerYear);
        assertEq(emission.collateralRewardTokensPerYear, collateralRewardTokensPerYear);
        assertEq(emission.startTimestamp, startTimestamp);
        assertEq(emission.endTimestamp, endTimestamp);
    }

    function testSetTimedRewardsEmissionShouldRevertWhenStartTimestampIsInThePast(
        address caller,
        TimedRewardsEmission calldata emission
    ) public {
        // The start timestamp is set in the past.
        vm.assume(emission.startTimestamp < block.timestamp);
        vm.assume(emission.endTimestamp > emission.startTimestamp);

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.START_TIMESTAMP_IN_THE_PAST));
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
        vm.expectRevert(bytes(ErrorsLib.END_TIMESTAMP_TOO_EARLY));
        dataProvider.setTimedRewardsEmission(address(0), address(0), Id.wrap(bytes32(uint256(0))), emission);
    }

    function testSetRewardsShouldRevertWhenSameCallerWantsToUpdateTheSameEmission(
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

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.REWARDS_EMISSION_ALREADY_SET));
        dataProvider.setTimedRewardsEmission(urd, token, market, emission);
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

        (
            uint256 supplyRewardTokensPerYear0,
            uint256 borrowRewardTokensPerYear0,
            uint256 collateralRewardTokensPerYear0,
            uint256 startTimestamp0,
            uint256 endTimestamp0
        ) = dataProvider.timedRewardsEmissions(
            computeTimedRewardsEmissionId(address(this), address(0), address(0), Id.wrap(bytes32(uint256(1))))
        );
        (
            uint256 supplyRewardTokensPerYear1,
            uint256 borrowRewardTokensPerYear1,
            uint256 collateralRewardTokensPerYear1,
            uint256 startTimestamp1,
            uint256 endTimestamp1
        ) = dataProvider.timedRewardsEmissions(
            computeTimedRewardsEmissionId(address(this), address(1), address(1), Id.wrap(bytes32(uint256(2))))
        );
        (
            uint256 supplyRewardTokensPerYear2,
            uint256 borrowRewardTokensPerYear2,
            uint256 collateralRewardTokensPerYear2,
            uint256 startTimestamp2,
            uint256 endTimestamp2
        ) = dataProvider.timedRewardsEmissions(
            computeTimedRewardsEmissionId(address(this), address(2), address(2), Id.wrap(bytes32(uint256(3))))
        );
        assertEq(supplyRewardTokensPerYear0, 1);
        assertEq(borrowRewardTokensPerYear0, 1);
        assertEq(collateralRewardTokensPerYear0, 1);
        assertEq(startTimestamp0, block.timestamp);
        assertEq(endTimestamp0, block.timestamp + 1);
        assertEq(supplyRewardTokensPerYear1, 2);
        assertEq(borrowRewardTokensPerYear1, 2);
        assertEq(collateralRewardTokensPerYear1, 2);
        assertEq(startTimestamp1, block.timestamp + 1);
        assertEq(endTimestamp1, block.timestamp + 2);
        assertEq(supplyRewardTokensPerYear2, 3);
        assertEq(borrowRewardTokensPerYear2, 3);
        assertEq(collateralRewardTokensPerYear2, 3);
        assertEq(startTimestamp2, block.timestamp + 2);
        assertEq(endTimestamp2, block.timestamp + 3);
    }

    function computeTimedRewardsEmissionId(address caller, address urd, address token, Id market)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(caller, urd, token, market));
    }
}
