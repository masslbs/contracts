// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Payments} from "../src/Payments.sol";
import "../src/IPayments.sol";

contract PaymentsTest is Test {
    Payments internal payments;
    IPermit2 permit2;
    address payable alice = payable(address(19));
    address customer = address(20);

    function setUp() public {
        permit2 =  IPermit2(address(new DeployPermit2()));
        payments = new Payments(
            permit2
        );
    }

    function makeTestPayment100Native (uint256 amount, uint256 time, address currency) public {
        payments.payNative{value: amount}(
            PaymentIntent({
                ttl: time,
                receipt: bytes32(0),
                currency: currency,
                amount: 100,
                payee: PaymentEndpoint({
                    payeeAddress: alice,
                    payload: new bytes(0),
                    canRevert: false
                }),
                shopId: 1,
                shopSignature: new bytes(65),
                permit2signature: new bytes(0)
            })
        );
    }

    function testPayNative() public {
        makeTestPayment100Native(100, block.timestamp + 100, address(0));
        assertEq(alice.balance, 100);
    }

    function test_DoublePay() public {
        makeTestPayment100Native(100, block.timestamp + 100, address(0));
        vm.expectRevert(IPayments.PaymentAlreadyMade.selector);
        makeTestPayment100Native(100, block.timestamp + 100, address(0));
    }

    function test_PayWrongAmount() public {
        vm.expectRevert(IPayments.InvalidPaymentAmount.selector);
        makeTestPayment100Native(99, block.timestamp + 100, address(0));
    }

    function test_PayWrongCurrency() public {
        vm.expectRevert(IPayments.InvalidPaymentToken.selector);
        makeTestPayment100Native(99, block.timestamp + 100, address(1));
    }
}
