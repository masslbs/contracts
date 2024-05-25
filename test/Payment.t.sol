// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import "permit2/src/interfaces/IPermit2.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Payments} from "../src/Payments.sol";
import "../src/IPayments.sol";
import {MockERC20} from "solady/test/utils/mocks/MockERC20.sol";

interface DepositEvent {
    event Deposit(address indexed sender, uint256 amount);
}

contract TestPaymentEndpoint is IPaymentEndpoint, DepositEvent {
    function pay(PaymentRequest calldata payment) external payable {
        emit Deposit(address(uint160(bytes20(payment.payeeAddress))), msg.value);
    }
}

contract PaymentsTest is Test, DepositEvent, DeployPermit2 {
    Payments internal payments;
    IPermit2 permit2;
    IPaymentEndpoint paymentEndpoint;
    address payable alice = payable(address(19));
    address customer = address(20);
    MockERC20 testToken;
    bytes32 DOMAIN_SEPARATOR;

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );
    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    function setUp() public {
        permit2 = IPermit2(address(deployPermit2()));
        payments = new Payments(permit2);
        paymentEndpoint = new TestPaymentEndpoint();
        testToken = new MockERC20("mock", "MCK", 18);
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();
    }

    function getPermitTransferSignature(
        ISignatureTransfer.PermitTransferFrom memory permit,
        uint256 privateKey,
        address spender,
        bytes32 domainSeparator
    ) internal view returns (bytes memory sig) {
        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(_PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissions, spender, permit.nonce, permit.deadline)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }

    function makeTestPayment100Native(uint256 amount, uint256 time, address currency) public {
        payments.payNative{value: amount}(
            PaymentRequest({
                ttl: time,
                order: bytes32(0),
                currency: currency,
                amount: 100,
                payeeAddress: alice,
                chainId: block.chainid, 
                isPaymentEndpoint: false,
                shopId: 1,
                shopSignature: new bytes(65)
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

    function test_PayEndpoint() public {
        vm.expectEmit();
        emit Deposit(address(paymentEndpoint), 100);

        payments.payNative{value: 100}(
            PaymentRequest({
                ttl: 100,
                order: bytes32(0),
                currency: address(0),
                amount: 100,
                payeeAddress: address(paymentEndpoint),
                chainId: block.chainid,
                isPaymentEndpoint: true,
                shopId: 1,
                shopSignature: new bytes(65)
            })
        );
        assertEq(address(paymentEndpoint).balance, 100);
    }

    function test_payTokenPreApproved() public {
        testToken.mint(address(this), 100);
        testToken.approve(address(payments), 100);
        payments.payTokenPreApproved(
            PaymentRequest({
                ttl: 100,
                order: bytes32(0),
                currency: address(testToken),
                amount: 100,
                payeeAddress: alice, 
                chainId: block.chainid,
                isPaymentEndpoint: false,
                shopId: 1,
                shopSignature: new bytes(65)
            })
        );
        assertEq(testToken.balanceOf(address(alice)), 100);
    }

    function test_payToken() public {
        uint256 fromPrivateKey = 0x12341234;
        address from = vm.addr(fromPrivateKey);
        testToken.mint(from, 100);
        vm.prank(from);
        testToken.approve(address(permit2), 100);

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(testToken), amount: 100}),
            nonce: 0,
            deadline: 100
        });

        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, address(payments), DOMAIN_SEPARATOR);

        vm.prank(from);
        payments.payToken(
            PaymentRequest({
                ttl: 100,
                order: bytes32(0),
                currency: address(testToken),
                amount: 100,
                payeeAddress: alice,
                chainId: block.chainid, 
                isPaymentEndpoint: false,
                shopId: 1,
                shopSignature: new bytes(65)
            }),
            sig
        );
        assertEq(testToken.balanceOf(address(alice)), 100);
    }
}
