// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/EmissionDataProvider.sol";

contract EmissionDataProviderTest is Test {
    EmissionDataProvider dataProvider;

    bytes[] internal data;

    event RewardsEmissionSet(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        RewardsEmission rewardsEmission
    );

    function setUp() public {
        dataProvider = new EmissionDataProvider();
    }

    function testSetRewardsEmission(
        address caller,
        address token,
        address urd,
        Id market,
        RewardsEmission calldata emission
    ) public {
        vm.assume(emission.startTimestamp >= block.timestamp);
        vm.assume(emission.endTimestamp > emission.startTimestamp);

        vm.expectEmit();
        emit RewardsEmissionSet(token, market, caller, urd, emission);
        vm.prank(caller);
        dataProvider.setRewardsEmission(token, urd, market, emission);

        (
            uint256 supplyRewardTokensPerYear,
            uint256 borrowRewardTokensPerYear,
            uint256 collateralRewardTokensPerYear,
            uint256 startTimestamp,
            uint256 endTimestamp
        ) = dataProvider.rewardsEmissions(keccak256(abi.encode(caller, urd, token, market)));

        assertEq(emission.supplyRewardTokensPerYear, supplyRewardTokensPerYear);
        assertEq(emission.borrowRewardTokensPerYear, borrowRewardTokensPerYear);
        assertEq(emission.collateralRewardTokensPerYear, collateralRewardTokensPerYear);
        assertEq(emission.startTimestamp, startTimestamp);
        assertEq(emission.endTimestamp, endTimestamp);
    }

    function testSetRewardsEmissionShouldRevertWhenStartTimestampIsInThePast(
        address caller,
        RewardsEmission calldata emission
    ) public {
        // The start timestamp is set in the past.
        vm.assume(emission.startTimestamp < block.timestamp);
        vm.assume(emission.endTimestamp > emission.startTimestamp);

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.START_TIMESTAMP_IN_THE_PAST));
        dataProvider.setRewardsEmission(address(0), address(0), Id.wrap(bytes32(uint256(0))), emission);
    }

    function testSetRewardsEmissionShouldRevertWhenEndTimestampIsBeforeStartTimestamp(
        address caller,
        RewardsEmission calldata emission
    ) public {
        vm.assume(emission.startTimestamp >= block.timestamp);
        // The end timestamp is set before the start timestamp.
        vm.assume(emission.endTimestamp < emission.startTimestamp);

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.END_TIMESTAMP_TOO_EARLY));
        dataProvider.setRewardsEmission(address(0), address(0), Id.wrap(bytes32(uint256(0))), emission);
    }

    function testSetRewardsShouldRevertWhenSameCallerWantsToUpdateTheSameEmission(
        address caller,
        address token,
        address urd,
        Id market,
        RewardsEmission calldata emission
    ) public {
        vm.assume(emission.startTimestamp >= block.timestamp);
        vm.assume(emission.endTimestamp > emission.startTimestamp);

        vm.prank(caller);
        dataProvider.setRewardsEmission(token, urd, market, emission);

        vm.prank(caller);
        vm.expectRevert(bytes(ErrorsLib.REWARDS_EMISSION_ALREADY_SET));
        dataProvider.setRewardsEmission(token, urd, market, emission);
    }

    function testMulticall() public {
        data.push(
            abi.encodeCall(
                EmissionDataProvider.setRewardsEmission,
                (
                    address(0),
                    address(0),
                    Id.wrap(bytes32(uint256(1))),
                    RewardsEmission(1, 1, 1, block.timestamp, block.timestamp + 1)
                )
            )
        );
        data.push(
            abi.encodeCall(
                EmissionDataProvider.setRewardsEmission,
                (
                    address(1),
                    address(1),
                    Id.wrap(bytes32(uint256(2))),
                    RewardsEmission(2, 2, 2, block.timestamp + 1, block.timestamp + 2)
                )
            )
        );
        data.push(
            abi.encodeCall(
                EmissionDataProvider.setRewardsEmission,
                (
                    address(2),
                    address(2),
                    Id.wrap(bytes32(uint256(3))),
                    RewardsEmission(3, 3, 3, block.timestamp + 2, block.timestamp + 3)
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
        ) = dataProvider.rewardsEmissions(
            computeRewardEmissionId(address(this), address(0), address(0), Id.wrap(bytes32(uint256(1))))
        );
        (
            uint256 supplyRewardTokensPerYear1,
            uint256 borrowRewardTokensPerYear1,
            uint256 collateralRewardTokensPerYear1,
            uint256 startTimestamp1,
            uint256 endTimestamp1
        ) = dataProvider.rewardsEmissions(
            computeRewardEmissionId(address(this), address(1), address(1), Id.wrap(bytes32(uint256(2))))
        );
        (
            uint256 supplyRewardTokensPerYear2,
            uint256 borrowRewardTokensPerYear2,
            uint256 collateralRewardTokensPerYear2,
            uint256 startTimestamp2,
            uint256 endTimestamp2
        ) = dataProvider.rewardsEmissions(
            computeRewardEmissionId(address(this), address(2), address(2), Id.wrap(bytes32(uint256(3))))
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

    function computeRewardEmissionId(address caller, address urd, address token, Id market)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(caller, urd, token, market));
    }
}
