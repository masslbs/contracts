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

import {MockERC20} from "solady/test/utils/mocks/MockERC20.sol";

contract PaymentFactoryTest is Test, DeployPermit2 {
    PaymentFactory private factory;
    Payments internal payments;
    IPermit2 internal permit2;
    MockERC20 internal testToken;

    address generatedAddress;
    address payable merchant;
    address payable refund;
    // ether
    address currency = address(0);
    uint256 shopId;


    function setUp() public {
        permit2 = IPermit2(address(deployPermit2()));
        payments = new Payments(permit2);
        factory = new PaymentFactory(payments);
        testToken = new MockERC20("mock", "MCK", 18);
        merchant = payable(address(uint160(vm.unixTime())));
        refund = payable(address(uint160(vm.unixTime() + 1)));
        shopId = vm.unixTime();
    }

    function getPaymentRequest(bool useTestToken) private returns (PaymentRequest memory) {
        PaymentRequest memory payment = PaymentRequest({
            ttl: 10000,
            order: bytes32(0),
            currency: useTestToken ? address(testToken) : currency,
            amount: 100,
            payeeAddress: merchant,
            chainId: block.chainid,
            isPaymentEndpoint: false,
            shopId: shopId,
            shopSignature: new bytes(0)
        });
        return payment;
    }

    function test_ProcessPayment() public {
        PaymentRequest memory payment = getPaymentRequest(false); 
        generatedAddress = factory.getPaymentAddress(payment, refund);
        deal(generatedAddress, payment.amount);
        factory.processPayment(payment, refund);
        assertEq(merchant.balance, payment.amount, "the sweep contract should send the corret amount");
    }

    function test_UnderPayment() public {
        PaymentRequest memory payment = getPaymentRequest(false); 
        generatedAddress = factory.getPaymentAddress(payment, refund);
        deal(generatedAddress, payment.amount - 1);
        factory.processPayment(payment, refund);
        assertEq(refund.balance, payment.amount - 1, "the sweep contract should return the ether if not enought was payed");
    }

    function test_OverPayment() public {
        PaymentRequest memory payment = getPaymentRequest(false); 
        generatedAddress = factory.getPaymentAddress(payment, refund);
        deal(generatedAddress, payment.amount + 1);

        factory.processPayment(payment, refund);
        assertEq(refund.balance, 1, "the sweep contract should refund the overpayed ether");
        assertEq(merchant.balance, payment.amount, "the sweep contract should send the corret amount");
    }

    function test_invalidPayment() public {
        PaymentRequest memory payment = getPaymentRequest(false); 
        payment.ttl = 0;
        generatedAddress = factory.getPaymentAddress(payment, refund);
        deal(generatedAddress, payment.amount);
        factory.processPayment(payment, refund);
        assertEq(refund.balance, payment.amount, "the sweep contract should refund the ether if the payment is invalid");
    }


    function test_payWithErc20() public {
        PaymentRequest memory payment = getPaymentRequest(true); 
        generatedAddress = factory.getPaymentAddress(payment, refund);
        testToken.mint(generatedAddress, payment.amount);
        factory.processPayment(payment, refund);
        assertEq(testToken.balanceOf(merchant), payment.amount, "the sweep contract should pay the ERC20 token");
    }

    function test_UnderPaymentERC20() public {
        PaymentRequest memory payment = getPaymentRequest(true); 
        generatedAddress = factory.getPaymentAddress(payment, refund);
        testToken.mint(generatedAddress, payment.amount - 1);
        factory.processPayment(payment, refund);
        assertEq(testToken.balanceOf(refund), payment.amount - 1, "the sweep contract should return the ERC20 if not enought was payed");
    }

    function test_OverPaymentERC20() public {
        PaymentRequest memory payment = getPaymentRequest(true); 
        generatedAddress = factory.getPaymentAddress(payment, refund);
        testToken.mint(generatedAddress, payment.amount + 1);
        factory.processPayment(payment, refund);
        assertEq(testToken.balanceOf(refund), 1, "the sweep contract should return the overpayed ERC20");
        assertEq(testToken.balanceOf(merchant), payment.amount, "the sweep contract should send the corret amount");
    }

    function test_InvalidPaymentERC20() public {
        PaymentRequest memory payment = getPaymentRequest(true); 
        payment.ttl = 0;
        generatedAddress = factory.getPaymentAddress(payment, refund);
        testToken.mint(generatedAddress, payment.amount);
        factory.processPayment(payment, refund);
        assertEq(testToken.balanceOf(refund), payment.amount, "the sweep contract should refund the ERC20 if the payment is invalid");
    }
}
