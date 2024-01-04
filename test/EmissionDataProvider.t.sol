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

        (uint256 supplyRatePerYear, uint256 borrowRatePerYear, uint256 collateralRatePerYear) =
            dataProvider.rewardsEmissions(caller, urd, token, market);

        assertEq(emission.supplyRatePerYear, supplyRatePerYear);
        assertEq(emission.borrowRatePerYear, borrowRatePerYear);
        assertEq(emission.collateralRatePerYear, collateralRatePerYear);
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

        (uint256 supplyRatePerYear0, uint256 borrowRatePerYear0, uint256 collateralRatePerYear0) =
            dataProvider.rewardsEmissions(address(this), address(0), address(0), Id.wrap(bytes32(uint256(1))));
        (uint256 supplyRatePerYear1, uint256 borrowRatePerYear1, uint256 collateralRatePerYear1) =
            dataProvider.rewardsEmissions(address(this), address(1), address(1), Id.wrap(bytes32(uint256(2))));
        (uint256 supplyRatePerYear2, uint256 borrowRatePerYear2, uint256 collateralRatePerYear2) =
            dataProvider.rewardsEmissions(address(this), address(2), address(2), Id.wrap(bytes32(uint256(3))));
        assertEq(supplyRatePerYear0, 1);
        assertEq(borrowRatePerYear0, 1);
        assertEq(collateralRatePerYear0, 1);
        assertEq(supplyRatePerYear1, 2);
        assertEq(borrowRatePerYear1, 2);
        assertEq(collateralRatePerYear1, 2);
        assertEq(supplyRatePerYear2, 3);
        assertEq(borrowRatePerYear2, 3);
        assertEq(collateralRatePerYear2, 3);
    }
}
