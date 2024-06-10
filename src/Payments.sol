// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";
import "./IPayments.sol";

address constant ETH = address(0);

contract Payments is IPayments {
    using LibBitmap for LibBitmap.Bitmap;
    // a map of payment status indexed by the order hash

    IPermit2 permit2;
    LibBitmap.Bitmap paymentBitmap;

    constructor(IPermit2 _permit2) {
        permit2 = _permit2;
    }

    /// @inheritdoc IPaymentFunctions
    function payNative(PaymentRequest calldata payment) public payable {
        if (payment.currency != ETH) revert InvalidPaymentToken();
        if (block.timestamp > payment.ttl) revert PaymentExpired();
        if (msg.value != payment.amount) revert InvalidPaymentAmount();
        if (payment.chainId != block.chainid) revert WrongChain();
        // this also prevents reentrancy so it must come before the transfer
        _usePaymentRequest(msg.sender, payment);
        if (payment.isPaymentEndpoint) {
            IPaymentEndpoint(payment.payeeAddress).pay{value: msg.value}(payment);
        } else {
            payable(payment.payeeAddress).transfer(msg.value);
        }
    }

    /// @inheritdoc IPaymentFunctions
    function payToken(PaymentRequest calldata payment, bytes calldata permit2signature) public {
        _usePaymentRequest(msg.sender, payment);
        // do a permit2 transfer
        permit2.permitTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: payment.currency, amount: payment.amount}),
                nonce: uint256(payment.order),
                deadline: payment.ttl
            }),
            ISignatureTransfer.SignatureTransferDetails({requestedAmount: payment.amount, to: payment.payeeAddress}),
            msg.sender,
            permit2signature
        );
        if (payment.isPaymentEndpoint) {
            IPaymentEndpoint(payment.payeeAddress).pay(payment);
        }
    }

    /// @inheritdoc IPaymentFunctions
    function payTokenPreApproved(PaymentRequest calldata payment) public {
        if (block.timestamp > payment.ttl) revert PaymentExpired();
        if (payment.chainId != block.chainid) revert WrongChain();
        // this also prevent reentrancy so it must come before the transfer
        _usePaymentRequest(msg.sender, payment);
        SafeTransferLib.safeTransferFrom(payment.currency, msg.sender, payment.payeeAddress, payment.amount);
        if (payment.isPaymentEndpoint) {
            IPaymentEndpoint(payment.payeeAddress).pay(payment);
        }
    }

    /// @inheritdoc IPaymentFunctions
    function pay(PaymentRequest calldata payment) public payable {
        if (payment.currency == ETH) {
            payNative(payment);
        } else {
            payTokenPreApproved(payment);
        }
    }

    /// @inheritdoc IPaymentFunctions
    function multiPay(PaymentRequest[] calldata payments, bytes[] calldata permit2Sigs) public payable {
        for (uint256 i = 0; i < payments.length; i++) {
            if (permit2Sigs[i].length > 0) {
                payToken(payments[i], permit2Sigs[i]);
            } else {
                pay(payments[i]);
            }
        }
    }

    // @inheritdoc IPaymentFunctions
    function revertPayment(address from, PaymentRequest calldata payment) public {
        if (msg.sender != payment.payeeAddress) revert NotPayee();
        uint256 paymentId = getPaymentId(payment);
        bool flipped = paymentBitmap.toggle(uint256(uint160(from)) ^ paymentId);
        if (flipped) revert PaymentNotMade();
    }

    // @inheritdoc IPaymentFunctions
    function hasPaymentBeenMade(address from, PaymentRequest calldata payment) public view returns (bool) {
        return paymentBitmap.get(uint256(uint160(from)) ^ getPaymentId(payment));
    }

    // @inheritdoc IPaymentFunctions
    function getPaymentId(PaymentRequest calldata payment) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(payment)));
    }

    /// @notice Checks whether a payment has been made and sets the bit at the bit position in the bitmap at the word position
    /// @param from The address to use to make the payment
    /// @param payment The payment
    function _usePaymentRequest(address from, PaymentRequest calldata payment) internal {
        uint256 paymentId = getPaymentId(payment);
        emit PaymentMade(paymentId);
        bool flipped = paymentBitmap.toggle(uint256(uint160(from)) ^ paymentId);
        if (!flipped) revert PaymentAlreadyMade();
    }
}
