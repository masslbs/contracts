// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {ShopReg} from "../src/ShopReg.sol";
import {OrderPaymentsFactory} from "../src/OrderPayments.sol";
import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";



contract EuroDollar is ERC20 {
    constructor() ERC20("Eddies", "EDD") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract Deploy is Script {
    bytes32 salt = bytes32(uint256(1));

    function deployContracts(bool testErc20, bool mut) external {
        vm.startBroadcast();

        // deploy shop registary
        ShopReg shop = new ShopReg{salt: salt}();

        deployPayments();

        string memory addresses;

        if (testErc20) {
            EuroDollar eddies = new EuroDollar{salt: salt}();
            vm.serializeAddress(addresses, "Eddies", address(eddies));
            // create a test shop
            address testAddress = tx.origin;
            bytes32 testSchema = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
            shop.mint(1, testSchema, testAddress);
        }

        string memory out = vm.serializeAddress(addresses, "ShopReg", address(shop));
        console.log("ShopReg Address: %s", out);

        if (mut) vm.writeJson(out, "./deploymentAddresses.json");
        vm.stopBroadcast();
    }

    function deployPayments() internal returns (string memory) {
        string memory addresses;
        // create the payments contract
        OrderPaymentsFactory payments = new OrderPaymentsFactory{salt: salt}();
        return vm.serializeAddress(addresses, "OrderPaymentsFactory", address(payments));
    }
}
