// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import "permit2/src/interfaces/IPermit2.sol";

import "../src/PaymentFactory.sol";
import "../src/IPayments.sol";
import {Payments} from "../src/Payments.sol";

contract PaymentFactoryTest is Test, DeployPermit2 {
    PaymentFactory private factory;
    address generatedAddress;

    address payable merchant = payable(address(21));
    address payable refund = payable(address(22));
    address currency = address(0);
    uint256 amount = 5;
    // just a random hash
    bytes32 recieptHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;

    Payments internal payments;
    IPermit2 permit2;

    function setUp() public {
        permit2 = IPermit2(address(deployPermit2()));
        payments = new Payments(permit2);
        factory = new PaymentFactory(payments);
    }

    function test_ProcessPayment() public {
        PaymentRequest memory payment = PaymentRequest({
                ttl: 10000,
                order: bytes32(0),
                currency: currency,
                amount: 100,
                payeeAddress: merchant,
                chainId: block.chainid,
                isPaymentEndpoint: false,
                shopId: 1,
                shopSignature: new bytes(0)
            }); 
        generatedAddress = factory.getPaymentAddress(payment, refund);
        deal(generatedAddress, payment.amount);
        factory.processPayment(payment, refund);
        assertEq(merchant.balance, payment.amount, "the payout contract should send the corret amount");
    }

    // function test_UnderPayment() public {
    //     deal(generatedAddress, amount - 1);
    //     factory.processPayment(merchant, proof, amount, currency, recieptHash);
    //     assertEq(proof.balance, amount - 1, "the payout contract should return the ether if not enought was payed");
    // }
    //
    // function test_OverPayment() public {
    //     deal(generatedAddress, amount + 1);
    //     deal(proof, 0);
    //     deal(merchant, 0);
    //
    //     factory.processPayment(merchant, proof, amount, currency, recieptHash);
    //     assertEq(proof.balance, 1, "the payout contract should return the ether if not enought was payed");
    //     assertEq(merchant.balance, amount, "the payout contract should send the corret amount");
    // }
}
