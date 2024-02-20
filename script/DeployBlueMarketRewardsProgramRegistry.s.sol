// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "src/BlueMarketRewardsProgramRegistry.sol";

contract DeployBlueMarketRewardsProgramRegistry is Script {
    bytes32 internal constant SALT = bytes32(0);

    function run() public {
        vm.broadcast();
        BlueMarketRewardsProgramRegistry registry = new BlueMarketRewardsProgramRegistry{salt: SALT}();
        console2.log("BlueMarketRewardsProgramRegistry deployed at address: ", address(registry));
    }
}
