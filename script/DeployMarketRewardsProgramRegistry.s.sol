// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "src/MarketRewardsProgramRegistry.sol";

contract DeployMarketRewardsProgramRegistry is Script {
    bytes32 internal constant SALT = bytes32(0);

    function run() public {
        vm.broadcast();
        MarketRewardsProgramRegistry registry = new MarketRewardsProgramRegistry{salt: SALT}();
        console2.log("MarketRewardsProgramRegistry deployed at address: ", address(registry));
    }
}
