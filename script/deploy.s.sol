
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/store-reg.sol";
import "../src/relay-reg.sol";
import "../src/payment-factory.sol";
import {MockERC20 } from "solady/test/utils/mocks/MockERC20.sol";

contract EuroDollarToken is MockERC20 {
    constructor (string memory _name, string memory _symbol, uint8 _decimals) MockERC20(_name, _symbol, _decimals) {
    }
}

contract Deploy is Script {
    bytes32 salt = bytes32(uint256(1));
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // need to be the address of the PRIVATE_KEY
        address testAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        // deploy relay registary
        RelayReg relayReg = new RelayReg{salt: salt}();
        // deploy store registary
        StoreReg store = new StoreReg{salt: salt}(relayReg);
        // create the payment factory
        new PaymentFactory{salt: salt}();
        // create a test store
        store.mint(1, testAddress);
        vm.stopBroadcast();
    }
}

contract TestingDeploy is Script {
    bytes32 salt = bytes32(uint256(1));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // need to be the address of the PRIVATE_KEY
        address testAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        // deploy relay registary
        RelayReg relayReg = new RelayReg{salt: salt}();
        // deploy store registary
        StoreReg store = new StoreReg{salt: salt}(relayReg);
        // create the payment factory
        new PaymentFactory{salt: salt}();
        // create a test store
        store.mint(1, testAddress);
        new EuroDollarToken("Eddies", "EDD", 2);
        vm.stopBroadcast();
    }
}
