// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "src/BlueRewardsRegistry.sol";

contract DeployUniversalRewardsRegistry is Script {
    bytes32 internal constant SALT = bytes32(0);

    function run() public {
        vm.broadcast();
        BlueRewardsRegistry registry = new BlueRewardsRegistry{salt: SALT}();
        console2.log("UniversalRewardsRegistry deployed at address: ", address(registry));
    }
}
