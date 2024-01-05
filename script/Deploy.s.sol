// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "src/EmissionDataProvider.sol";

contract Deploy is Script {
    bytes32 internal constant SALT = bytes32(0);

    function run() public {
        vm.broadcast();
        EmissionDataProvider dataProvider = new EmissionDataProvider{salt: SALT}();
        console2.log("EmissionDataProvider deployed at address: ", address(dataProvider));
    }
}
