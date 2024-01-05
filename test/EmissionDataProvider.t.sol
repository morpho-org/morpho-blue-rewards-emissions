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
        vm.expectEmit();
        emit RewardsEmissionSet(token, market, caller, urd, emission);
        vm.prank(caller);
        dataProvider.setRewardsEmission(token, urd, market, emission);

        (uint256 supplyRewardTokensPerYear, uint256 borrowRewardTokensPerYear, uint256 collateralRewardTokensPerYear) =
            dataProvider.rewardsEmissions(caller, urd, token, market);

        assertEq(emission.supplyRewardTokensPerYear, supplyRewardTokensPerYear);
        assertEq(emission.borrowRewardTokensPerYear, borrowRewardTokensPerYear);
        assertEq(emission.collateralRewardTokensPerYear, collateralRewardTokensPerYear);
    }

    function testMulticall() public {
        data.push(
            abi.encodeCall(
                EmissionDataProvider.setRewardsEmission,
                (address(0), address(0), Id.wrap(bytes32(uint256(1))), RewardsEmission(1, 1, 1))
            )
        );
        data.push(
            abi.encodeCall(
                EmissionDataProvider.setRewardsEmission,
                (address(1), address(1), Id.wrap(bytes32(uint256(2))), RewardsEmission(2, 2, 2))
            )
        );
        data.push(
            abi.encodeCall(
                EmissionDataProvider.setRewardsEmission,
                (address(2), address(2), Id.wrap(bytes32(uint256(3))), RewardsEmission(3, 3, 3))
            )
        );

        dataProvider.multicall(data);

        (uint256 supplyRewardTokensPerYear0, uint256 borrowRewardTokensPerYear0, uint256 collateralRewardTokensPerYear0)
        = dataProvider.rewardsEmissions(address(this), address(0), address(0), Id.wrap(bytes32(uint256(1))));
        (uint256 supplyRewardTokensPerYear1, uint256 borrowRewardTokensPerYear1, uint256 collateralRewardTokensPerYear1)
        = dataProvider.rewardsEmissions(address(this), address(1), address(1), Id.wrap(bytes32(uint256(2))));
        (uint256 supplyRewardTokensPerYear2, uint256 borrowRewardTokensPerYear2, uint256 collateralRewardTokensPerYear2)
        = dataProvider.rewardsEmissions(address(this), address(2), address(2), Id.wrap(bytes32(uint256(3))));
        assertEq(supplyRewardTokensPerYear0, 1);
        assertEq(borrowRewardTokensPerYear0, 1);
        assertEq(collateralRewardTokensPerYear0, 1);
        assertEq(supplyRewardTokensPerYear1, 2);
        assertEq(borrowRewardTokensPerYear1, 2);
        assertEq(collateralRewardTokensPerYear1, 2);
        assertEq(supplyRewardTokensPerYear2, 3);
        assertEq(borrowRewardTokensPerYear2, 3);
        assertEq(collateralRewardTokensPerYear2, 3);
    }
}
