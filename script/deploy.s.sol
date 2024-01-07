
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/store-reg.sol";
import "../src/relay-reg.sol";
import "../src/payment-factory.sol";

contract Deploy is Script {
    bytes32 salt = bytes32(uint256(1));
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // need to be the address of the PRIVATE_KEY
        address testAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        // root hash for the store
        bytes32 rootHash = 0xf7da9dd69c40b660bedf17b0bafe9b16085e1bf34c6bc18655c5af3997aa5174;
        vm.startBroadcast(deployerPrivateKey);
        // deploy relay registary
        RelayReg relayReg = new RelayReg{salt: salt}();
        // deploy store registary
        StoreReg store = new StoreReg{salt: salt}(relayReg);
        // create the payment factory
        new PaymentFactory{salt: salt}();
        // create a test store
        store.registerStore(1, testAddress, rootHash);
        vm.stopBroadcast();
    }
}
