// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/BlueMarketRewardsProgramRegistry.sol";

contract BlueMarketRewardsProgramRegistryTest is Test {
    BlueMarketRewardsProgramRegistry registry;
    address internal USER = makeAddr("User");

    bytes[] internal data;

    event ProgramRegistered(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        MarketRewardsProgram program
    );

    function setUp() public {
        registry = new BlueMarketRewardsProgramRegistry();
    }

    modifier assumeTimestampsAreValid(MarketRewardsProgram memory program) {
        vm.assume(program.startTimestamp >= block.timestamp);
        vm.assume(program.endTimestamp > program.startTimestamp);
        _;
    }

    function testRegister(address urd, Id market, address token, MarketRewardsProgram calldata program)
        public
        assumeTimestampsAreValid(program)
    {
        vm.expectEmit();
        emit ProgramRegistered(token, market, USER, urd, program);
        vm.prank(USER);
        registry.register(urd, address(token), market, program);

        MarketRewardsProgram[] memory registeredPrograms = registry.getPrograms(USER, urd, address(token), market);

        assertEq(program.supplyRewardTokensPerYear, registeredPrograms[0].supplyRewardTokensPerYear);
        assertEq(program.borrowRewardTokensPerYear, registeredPrograms[0].borrowRewardTokensPerYear);
        assertEq(program.collateralRewardTokensPerYear, registeredPrograms[0].collateralRewardTokensPerYear);
        assertEq(program.startTimestamp, registeredPrograms[0].startTimestamp);
        assertEq(program.endTimestamp, registeredPrograms[0].endTimestamp);
    }

    function testRegisterShouldRevertWhenStartTimestampIsInThePast(MarketRewardsProgram calldata program) public {
        // The start timestamp is set in the past.
        vm.assume(program.startTimestamp < block.timestamp);
        vm.assume(program.endTimestamp > program.startTimestamp);

        vm.prank(USER);
        vm.expectRevert(bytes(ErrorsLib.START_TIMESTAMP_OUTDATED));
        registry.register(address(0), address(0), Id.wrap(bytes32(uint256(0))), program);
    }

    function testRegisterShouldRevertWhenEndTimestampIsBeforeStartTimestamp(MarketRewardsProgram calldata program)
        public
    {
        vm.assume(program.startTimestamp >= block.timestamp);
        // The end timestamp is set before the start timestamp.
        vm.assume(program.endTimestamp < program.startTimestamp);

        vm.prank(USER);
        vm.expectRevert(bytes(ErrorsLib.END_TIMESTAMP_INVALID));
        registry.register(address(0), address(0), Id.wrap(bytes32(uint256(0))), program);
    }

    function testMulticall() public {
        address token1 = makeAddr("Token1");
        address token2 = makeAddr("Token2");
        address token3 = makeAddr("Token3");

        data.push(
            abi.encodeCall(
                registry.register,
                (
                    address(0),
                    token1,
                    Id.wrap(bytes32(uint256(1))),
                    MarketRewardsProgram(1, 1, 1, block.timestamp, block.timestamp + 1)
                )
            )
        );
        data.push(
            abi.encodeCall(
                registry.register,
                (
                    address(1),
                    token2,
                    Id.wrap(bytes32(uint256(2))),
                    MarketRewardsProgram(2, 2, 2, block.timestamp + 1, block.timestamp + 2)
                )
            )
        );
        data.push(
            abi.encodeCall(
                registry.register,
                (
                    address(2),
                    token3,
                    Id.wrap(bytes32(uint256(3))),
                    MarketRewardsProgram(3, 3, 3, block.timestamp + 2, block.timestamp + 3)
                )
            )
        );

        vm.prank(USER);
        registry.multicall(data);

        MarketRewardsProgram memory program0 =
            registry.getPrograms(USER, address(0), address(token1), Id.wrap(bytes32(uint256(1))))[0];
        MarketRewardsProgram memory program1 =
            registry.getPrograms(USER, address(1), address(token2), Id.wrap(bytes32(uint256(2))))[0];
        MarketRewardsProgram memory program2 =
            registry.getPrograms(USER, address(2), address(token3), Id.wrap(bytes32(uint256(3))))[0];

        assertEq(program0.supplyRewardTokensPerYear, 1);
        assertEq(program0.borrowRewardTokensPerYear, 1);
        assertEq(program0.collateralRewardTokensPerYear, 1);
        assertEq(program0.startTimestamp, block.timestamp);
        assertEq(program0.endTimestamp, block.timestamp + 1);
        assertEq(program1.supplyRewardTokensPerYear, 2);
        assertEq(program1.borrowRewardTokensPerYear, 2);
        assertEq(program1.collateralRewardTokensPerYear, 2);
        assertEq(program1.startTimestamp, block.timestamp + 1);
        assertEq(program1.endTimestamp, block.timestamp + 2);
        assertEq(program2.supplyRewardTokensPerYear, 3);
        assertEq(program2.borrowRewardTokensPerYear, 3);
        assertEq(program2.collateralRewardTokensPerYear, 3);
        assertEq(program2.startTimestamp, block.timestamp + 2);
        assertEq(program2.endTimestamp, block.timestamp + 3);
    }

    function testMulticallForSameURDSameTokenAndSameMarket() public {
        address urd = makeAddr("URD");
        address rewardToken = makeAddr("RewardToken");
        Id market = Id.wrap(bytes32(uint256(0)));

        uint8 MAX_PROGRAMS_WITH_SAME_ID = registry.MAX_PROGRAMS_WITH_SAME_ID();
        // create maximum programs for the same URD, token and market
        // with rewards for supply of 1
        for (uint256 i = 0; i < MAX_PROGRAMS_WITH_SAME_ID; i++) {
            data.push(
                abi.encodeCall(
                    registry.register,
                    (
                        urd,
                        rewardToken,
                        market,
                        MarketRewardsProgram(1, 0, 0, block.timestamp + i, block.timestamp + i + 1)
                    )
                )
            );
        }

        vm.prank(USER);
        registry.multicall(data);

        // get all the programs for the same URD, token and market
        MarketRewardsProgram[] memory programs = registry.getPrograms(USER, urd, rewardToken, market);

        for (uint256 i = 0; i < programs.length; i++) {
            assertEq(programs[i].supplyRewardTokensPerYear, 1);
            assertEq(programs[i].borrowRewardTokensPerYear, 0);
            assertEq(programs[i].collateralRewardTokensPerYear, 0);
            assertEq(programs[i].startTimestamp, block.timestamp + i);
            assertEq(programs[i].endTimestamp, block.timestamp + i + 1);
        }

        // add one more program for the same URD, token and market
        // with rewards for supply of 1
        // this should revert because there are already the maximum number of programs
        vm.prank(USER);
        vm.expectRevert(bytes(ErrorsLib.MAX_PROGRAMS_WITH_SAME_ID_EXCEEDED));
        registry.register(
            urd,
            rewardToken,
            market,
            MarketRewardsProgram(
                1,
                0,
                0,
                block.timestamp + MAX_PROGRAMS_WITH_SAME_ID, // this timestamp follows the last one
                block.timestamp + MAX_PROGRAMS_WITH_SAME_ID + 1
            )
        );
    }
}
