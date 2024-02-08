// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "src/BlueRewardsProgramRegistry.sol";

contract DeployBlueRewardsPorgramRegistry is Script {
    bytes32 internal constant SALT = bytes32(0);

    function run() public {
        vm.broadcast();
        BlueRewardsProgramRegistry registry = new BlueRewardsProgramRegistry{salt: SALT}();
        console2.log("BlueRewardsPorgramRegistry deployed at address: ", address(registry));
    }
}
