// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.21;

// import "forge-std/Script.sol";
// import "src/TimedEmissionDataProvider.sol";

// contract DeployTimed is Script {
//     bytes32 internal constant SALT = bytes32(0);

//     function run() public {
//         vm.broadcast();
//         TimedEmissionDataProvider dataProvider = new TimedEmissionDataProvider{salt: SALT}();
//         console2.log("TimedEmissionDataProvider deployed at address: ", address(dataProvider));
//     }
// }
