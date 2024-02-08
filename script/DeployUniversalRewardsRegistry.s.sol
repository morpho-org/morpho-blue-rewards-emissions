// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "src/UniversalRewardsRegistry.sol";

contract DeployUniversalRewardsRegistry is Script {
    bytes32 internal constant SALT = bytes32(0);

    function run() public {
        vm.broadcast();
        UniversalRewardsRegistry registry = new UniversalRewardsRegistry{salt: SALT}();
        console2.log("UniversalRewardsRegistry deployed at address: ", address(registry));
    }
}
