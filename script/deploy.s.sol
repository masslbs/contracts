// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import "permit2/src/interfaces/IPermit2.sol";

import "../src/StoreReg.sol";
import "../src/RelayReg.sol";
import "../src/Payments.sol";
import "../src/PaymentFactory.sol";
import {MockERC20} from "solady/test/utils/mocks/MockERC20.sol";

contract EuroDollar is MockERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals) MockERC20(_name, _symbol, _decimals) {}
}

contract Deploy is Script, DeployPermit2 {
    bytes32 salt = bytes32(uint256(1));

    function deployContracts(bool testERC20, bool mut) internal {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address permit2; 
        if (testERC20) {
            permit2 = address(deployPermit2());
        } else {
            permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
        }

        // deploy relay registary
        RelayReg relayReg = new RelayReg{salt: salt}();
        // deploy store registary
        StoreReg store = new StoreReg{salt: salt}(relayReg);
        // create the paryments contract
        Payments payments = new Payments{salt: salt}(IPermit2(permit2));
        // create the payment factory
        PaymentFactory paymentFactory = new PaymentFactory{salt: salt}(payments);

        string memory addresses;

        if (testERC20) {
            EuroDollar eddies = new EuroDollar{salt: salt}("Eddies", "EDD", 2);
            vm.serializeAddress(addresses, "Eddies", address(eddies));
            // create a test store
            address testAddress = vm.addr(deployerPrivateKey);
            store.mint(1, testAddress);
        }

        vm.serializeAddress(addresses, "Payments", address(payments));
        vm.serializeAddress(addresses, "RelayReg", address(relayReg));
        vm.serializeAddress(addresses, "StoreReg", address(store));
        string memory out = vm.serializeAddress(addresses, "PaymentFactory", address(paymentFactory));

        if (mut) vm.writeJson(out, "./deploymentAddresses.json");
        vm.stopBroadcast();
    }

    // we don't want to deploy the test contract but do want to recoded the addresses
    function runDeploy() external {
        deployContracts(false, true);
    }

    // we want to deploy the test contract and record the addresses
    function runTestDeploy() external {
        deployContracts(true, true);
    }

    // we want to deploy the test contract and cannot record the address
    // since we are running from nix store, ect
    function runTestDeployImmut() external {
        deployContracts(true, false);
    }
}
