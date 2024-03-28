// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/StoreReg.sol";
import "../src/RelayReg.sol";
import "../src/PaymentFactory.sol";
import {MockERC20} from "solady/test/utils/mocks/MockERC20.sol";

contract EuroDollar is MockERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals) MockERC20(_name, _symbol, _decimals) {}
}

contract Deploy is Script {
    bytes32 salt = bytes32(uint256(1));

    function deployContracts(bool testERC20) internal {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address testAddress = vm.addr(deployerPrivateKey);

        // deploy relay registary
        RelayReg relayReg = new RelayReg{salt: salt}();
        // deploy store registary
        StoreReg store = new StoreReg{salt: salt}(relayReg);
        // create the payment factory
        PaymentFactory paymentFactory = new PaymentFactory{salt: salt}();
        // create a test store
        store.mint(1, testAddress);

        string memory addresses;

        if (testERC20) {
            EuroDollar eddies = new EuroDollar{salt: salt}("Eddies", "EDD", 2);
            vm.serializeAddress(addresses, "Eddies", address(eddies));
        }
        vm.serializeAddress(addresses, "RelayReg", address(relayReg));
        vm.serializeAddress(addresses, "StoreReg", address(store));
        string memory out = vm.serializeAddress(addresses, "PaymentFactory", address(paymentFactory));

        vm.writeJson(out, "./deploymentAddresses.json");
        vm.stopBroadcast();
    }

    function run() external {
        deployContracts(false);
    }

    function runTestDeploy() external {
        deployContracts(true);
    }
}
