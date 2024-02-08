// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/UniversalRewardsRegistry.sol";
import {MockERC20} from "lib/solmate/src/test/utils/mocks/MockERC20.sol";

contract UniversalRewardsRegistryTest is Test {
    UniversalRewardsRegistry registry;
    uint256 public constant MAX_COMMITMENTS_WITH_SAME_ID = 100;
    address internal USER = makeAddr("User");

    bytes[] internal data;

    event RewardsCommitmentRegistered(
        address indexed rewardToken,
        Id indexed market,
        address indexed sender,
        address urd,
        RewardsCommitment commitment
    );

    function setUp() public {
        registry = new UniversalRewardsRegistry();
    }

    modifier assumeRewardsAreNotOverflowing(RewardsCommitment calldata commitment) {
        vm.assume(
            commitment.supplyRewardTokensPerYear > 0 || commitment.borrowRewardTokensPerYear > 0
                || commitment.collateralRewardTokensPerYear > 0
        );
        // realistic assumption, the three fields are less than 2^256 combined
        vm.assume(
            commitment.supplyRewardTokensPerYear < (type(uint256).max / 3)
                && commitment.borrowRewardTokensPerYear < (type(uint256).max / 3)
                && commitment.collateralRewardTokensPerYear < (type(uint256).max / 3)
        );
        _;
    }

    modifier assumeTimestampsAreValid(RewardsCommitment calldata commitment) {
        vm.assume(commitment.startTimestamp >= block.timestamp);
        vm.assume(commitment.endTimestamp > commitment.startTimestamp);
        _;
    }

    function testCommit(address urd, Id market, RewardsCommitment calldata commitment)
        public
        assumeTimestampsAreValid(commitment)
        assumeRewardsAreNotOverflowing(commitment)
    {
        uint256 userBalance = commitment.supplyRewardTokensPerYear + commitment.borrowRewardTokensPerYear
            + commitment.collateralRewardTokensPerYear;

        // create and mint ERC20
        MockERC20 token = new MockERC20("mock", "MOCK", 18);
        token.mint(USER, userBalance);

        // approve URR contract
        vm.prank(USER);
        ERC20(token).approve(address(registry), type(uint256).max);

        vm.expectEmit();
        emit RewardsCommitmentRegistered(address(token), market, USER, urd, commitment);
        vm.prank(USER);
        registry.register(urd, address(token), market, commitment);

        RewardsCommitment[100] memory registeredCommitments = registry.getCommitments(USER, urd, address(token), market);

        assertEq(commitment.supplyRewardTokensPerYear, registeredCommitments[0].supplyRewardTokensPerYear);
        assertEq(commitment.borrowRewardTokensPerYear, registeredCommitments[0].borrowRewardTokensPerYear);
        assertEq(commitment.collateralRewardTokensPerYear, registeredCommitments[0].collateralRewardTokensPerYear);
        assertEq(commitment.startTimestamp, registeredCommitments[0].startTimestamp);
        assertEq(commitment.endTimestamp, registeredCommitments[0].endTimestamp);
    }

    function testCommitShouldRevertWhenStartTimestampIsInThePast(RewardsCommitment calldata commitment)
        public
        assumeRewardsAreNotOverflowing(commitment)
    {
        // The start timestamp is set in the past.
        vm.assume(commitment.startTimestamp < block.timestamp);
        vm.assume(commitment.endTimestamp > commitment.startTimestamp);

        vm.prank(USER);
        vm.expectRevert(bytes(ErrorsLib.START_TIMESTAMP_OUTDATED));
        registry.register(address(0), address(0), Id.wrap(bytes32(uint256(0))), commitment);
    }

    function testCommitShouldRevertWhenEndTimestampIsBeforeStartTimestamp(RewardsCommitment calldata commitment)
        public
        assumeRewardsAreNotOverflowing(commitment)
    {
        vm.assume(commitment.startTimestamp >= block.timestamp);
        // The end timestamp is set before the start timestamp.
        vm.assume(commitment.endTimestamp < commitment.startTimestamp);

        vm.prank(USER);
        vm.expectRevert(bytes(ErrorsLib.END_TIMESTAMP_INVALID));
        registry.register(address(0), address(0), Id.wrap(bytes32(uint256(0))), commitment);
    }

    function testCommitShouldRevertWhenUserBalanceIsLessThanCommitmentAmount(RewardsCommitment calldata commitment)
        public
        assumeTimestampsAreValid(commitment)
        assumeRewardsAreNotOverflowing(commitment)
    {
        // The user balance will be less than the commitment amount by 1.
        uint256 userBalance = commitment.supplyRewardTokensPerYear + commitment.borrowRewardTokensPerYear
            + commitment.collateralRewardTokensPerYear - 1;

        // create and mint ERC20
        MockERC20 token = new MockERC20("mock", "MOCK", 18);
        token.mint(USER, userBalance);

        // approve URR contract
        vm.prank(USER);
        ERC20(token).approve(address(registry), type(uint256).max);

        vm.prank(USER);
        vm.expectRevert(bytes(ErrorsLib.COMMITMENT_INVALID_AMOUNTS));
        registry.register(address(0), address(token), Id.wrap(bytes32(uint256(0))), commitment);
    }

    function testCommitShouldSucceedWhenUserBalanceIsMoreThanCommitmentAmount(RewardsCommitment calldata commitment)
        public
        assumeTimestampsAreValid(commitment)
        assumeRewardsAreNotOverflowing(commitment)
    {
        // The user balance will be more than the commitment amount by 1.
        uint256 userBalance = commitment.supplyRewardTokensPerYear + commitment.borrowRewardTokensPerYear
            + commitment.collateralRewardTokensPerYear + 1;

        // create and mint ERC20
        MockERC20 token = new MockERC20("mock", "MOCK", 18);
        token.mint(USER, userBalance);

        // approve URR contract
        vm.prank(USER);
        ERC20(token).approve(address(registry), type(uint256).max);

        vm.prank(USER);
        registry.register(address(0), address(token), Id.wrap(bytes32(uint256(0))), commitment);
    }

    function testMulticall() public {
        uint256 userBalance = 100;
        // create and mint ERC20s
        MockERC20 token1 = new MockERC20("mock1", "MOCK1", 18);
        token1.mint(USER, userBalance);
        MockERC20 token2 = new MockERC20("mock2", "MOCK2", 18);
        token2.mint(USER, userBalance);
        MockERC20 token3 = new MockERC20("mock3", "MOCK3", 18);
        token3.mint(USER, userBalance);

        // approve URR contract
        vm.startPrank(USER);
        ERC20(token1).approve(address(registry), type(uint256).max);
        ERC20(token2).approve(address(registry), type(uint256).max);
        ERC20(token3).approve(address(registry), type(uint256).max);
        vm.stopPrank();

        data.push(
            abi.encodeCall(
                registry.register,
                (
                    address(0),
                    address(token1),
                    Id.wrap(bytes32(uint256(1))),
                    RewardsCommitment(1, 1, 1, block.timestamp, block.timestamp + 1)
                )
            )
        );
        data.push(
            abi.encodeCall(
                registry.register,
                (
                    address(1),
                    address(token2),
                    Id.wrap(bytes32(uint256(2))),
                    RewardsCommitment(2, 2, 2, block.timestamp + 1, block.timestamp + 2)
                )
            )
        );
        data.push(
            abi.encodeCall(
                registry.register,
                (
                    address(2),
                    address(token3),
                    Id.wrap(bytes32(uint256(3))),
                    RewardsCommitment(3, 3, 3, block.timestamp + 2, block.timestamp + 3)
                )
            )
        );

        vm.prank(USER);
        registry.multicall(data);

        RewardsCommitment memory commitment0 =
            registry.getCommitments(USER, address(0), address(token1), Id.wrap(bytes32(uint256(1))))[0];
        RewardsCommitment memory commitment1 =
            registry.getCommitments(USER, address(1), address(token2), Id.wrap(bytes32(uint256(2))))[0];
        RewardsCommitment memory commitment2 =
            registry.getCommitments(USER, address(2), address(token3), Id.wrap(bytes32(uint256(3))))[0];

        assertEq(commitment0.supplyRewardTokensPerYear, 1);
        assertEq(commitment0.borrowRewardTokensPerYear, 1);
        assertEq(commitment0.collateralRewardTokensPerYear, 1);
        assertEq(commitment0.startTimestamp, block.timestamp);
        assertEq(commitment0.endTimestamp, block.timestamp + 1);
        assertEq(commitment1.supplyRewardTokensPerYear, 2);
        assertEq(commitment1.borrowRewardTokensPerYear, 2);
        assertEq(commitment1.collateralRewardTokensPerYear, 2);
        assertEq(commitment1.startTimestamp, block.timestamp + 1);
        assertEq(commitment1.endTimestamp, block.timestamp + 2);
        assertEq(commitment2.supplyRewardTokensPerYear, 3);
        assertEq(commitment2.borrowRewardTokensPerYear, 3);
        assertEq(commitment2.collateralRewardTokensPerYear, 3);
        assertEq(commitment2.startTimestamp, block.timestamp + 2);
        assertEq(commitment2.endTimestamp, block.timestamp + 3);
    }

    function testMulticallForSameURDSameTokenAndSameMarket() public {
        // enough funds to cover all commitments
        uint256 userBalance = MAX_COMMITMENTS_WITH_SAME_ID + 1;
        // create and mint ERC20s
        MockERC20 token = new MockERC20("mock", "MOCK", 18);
        token.mint(USER, userBalance);

        // approve URR contract
        vm.prank(USER);
        ERC20(token).approve(address(registry), type(uint256).max);

        address urd = makeAddr("URD");
        address rewardToken = address(token);
        Id market = Id.wrap(bytes32(uint256(0)));

        // create 100 commitments for the same URD, token and market
        // with rewards for supply of 1
        for (uint256 i = 0; i < MAX_COMMITMENTS_WITH_SAME_ID; i++) {
            data.push(
                abi.encodeCall(
                    registry.register,
                    (urd, rewardToken, market, RewardsCommitment(1, 0, 0, block.timestamp + i, block.timestamp + i + 1))
                )
            );
        }

        vm.prank(USER);
        registry.multicall(data);

        // get all the commitments for the same URD, token and market
        RewardsCommitment[MAX_COMMITMENTS_WITH_SAME_ID] memory commitments =
            registry.getCommitments(USER, urd, rewardToken, market);

        for (uint256 i = 0; i < 100; i++) {
            assertEq(commitments[i].supplyRewardTokensPerYear, 1);
            assertEq(commitments[i].borrowRewardTokensPerYear, 0);
            assertEq(commitments[i].collateralRewardTokensPerYear, 0);
            assertEq(commitments[i].startTimestamp, block.timestamp + i);
            assertEq(commitments[i].endTimestamp, block.timestamp + i + 1);
        }

        // add one more commitment for the same URD, token and market
        // with rewards for supply of 1
        // this should revert because there are already the maximum number of commitments
        vm.prank(USER);
        vm.expectRevert(bytes(ErrorsLib.MAX_COMMITMENTS_WITH_SAME_ID_EXCEEDED));
        registry.register(
            urd,
            rewardToken,
            market,
            RewardsCommitment(
                1,
                0,
                0,
                block.timestamp + MAX_COMMITMENTS_WITH_SAME_ID, // this timestamp follows the last one
                block.timestamp + MAX_COMMITMENTS_WITH_SAME_ID + 1
            )
        );
    }
}
