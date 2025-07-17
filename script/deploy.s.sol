// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/ShopReg.sol";
import "../src/RelayReg.sol";
import "../src/OrderPayments.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EuroDollar is ERC20 {
    constructor() ERC20("Eddies", "EDD") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract Deploy is Script {
    bytes32 salt = bytes32(uint256(1));

    function deployContracts(bool testERC20, bool mut) external {
        vm.startBroadcast();

        // deploy relay registary
        RelayReg relayReg = new RelayReg{salt: salt}();
        // deploy shop registary
        ShopReg shop = new ShopReg{salt: salt}(relayReg);

        deployPayments();

        string memory addresses;

        if (testERC20) {
            EuroDollar eddies = new EuroDollar{salt: salt}();
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
        // create the payments contract
        OrderPaymentsFactory payments = new OrderPaymentsFactory();
        return vm.serializeAddress(addresses, "OrderPaymentsFactory", address(payments));
    }
}
