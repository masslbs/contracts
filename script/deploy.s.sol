// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import "permit2/src/interfaces/IPermit2.sol";

import "../src/ShopReg.sol";
import "../src/RelayReg.sol";
import "../src/PaymentsByAddress.sol";
import {MockERC20} from "solady/test/utils/mocks/MockERC20.sol";

contract EuroDollar is MockERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals) MockERC20(_name, _symbol, _decimals) {}
}

contract Deploy is Script, DeployPermit2 {
    bytes32 salt = bytes32(uint256(1));

    address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function deployContracts(bool testERC20, bool mut) internal {
        vm.startBroadcast();

        if (testERC20) {
            // should always get deployed to the above
            address(deployPermit2());
        }
        // deploy relay registary
        RelayReg relayReg = new RelayReg{salt: salt}();
        // deploy shop registary
        ShopReg shop = new ShopReg{salt: salt}(relayReg);

        deployPayments();

        string memory addresses;

        if (testERC20) {
            EuroDollar eddies = new EuroDollar{salt: salt}("Eddies", "EDD", 2);
            vm.serializeAddress(addresses, "Eddies", address(eddies));
            // create a test shop
            address testAddress = tx.origin;
            shop.mint(1, testAddress);
        }

        vm.serializeAddress(addresses, "RelayReg", address(relayReg));
        string memory out = vm.serializeAddress(addresses, "ShopReg", address(shop));

        if (mut) vm.writeJson(out, "./deploymentAddresses.json");
        vm.stopBroadcast();
    }

    function deployPayments() internal returns (string memory) {
        string memory addresses;
        // create the paryments contract
        PaymentsByAddress payments = new PaymentsByAddress{salt: salt}(IPermit2(permit2));
        return vm.serializeAddress(addresses, "Payments", address(payments));
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
    // since we are running from nix shop, etc
    function runTestDeployImmut() external {
        deployContracts(true, false);
    }
}
