// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Multicall} from "openzeppelin/utils/Multicall.sol";

struct RewardsEmission {
    uint256 supplyRatePerYear;
    uint256 borrowRatePerYear;
    uint256 collateralRatePerYear;
}

contract EmissionDataProvider is Ownable, Multicall {
    /// @notice reward token -> market -> RewardsEmission mapping
    mapping(address => mapping(bytes32 => RewardsEmission)) public rewardsEmissions;

    address public immutable REWARDS_DISTRIBUTOR;

    event RewardsEmissionSet(address indexed token, bytes32 indexed market, RewardsEmission rewardsEmission);

    constructor(address rewardsDistributor, address initialOwner) Ownable(initialOwner) Multicall() {
        REWARDS_DISTRIBUTOR = rewardsDistributor;
    }

    function setRewardsEmission(address token, bytes32 market, RewardsEmission calldata rewardsEmission)
        public
        onlyOwner
    {
        rewardsEmissions[token][market] = rewardsEmission;

        emit RewardsEmissionSet(token, market, rewardsEmission);
    }
}
