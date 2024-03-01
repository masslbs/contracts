// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { SafeTransferLib } from "solady/src/utils/SafeTransferLib.sol";
import { LibBitmap } from "solady/src/utils/LibBitmap.sol";

import "./IPayments.sol";

address constant ETH = address(0);

contract Payments is IPayments {
    using LibBitmap for LibBitmap.Bitmap;
    // a map of payment status indexed by the receipt hash
    IPermit2 permit2;
    LibBitmap.Bitmap paymentBitmap;

    constructor(
        IPermit2 _permit2
    ) 
    {
        permit2 = _permit2;
    }

    // @inheritdoc IPayments
    function payNative(
        PaymentIntent calldata payment
    ) public payable
    {
        if(payment.currency != ETH) revert InvalidPaymentToken();
        if(block.timestamp > payment.ttl) revert PaymentExpired();
        if(msg.value != payment.amount)   revert InvalidPaymentAmount();
        // this also prevents reentrancy so it must come before the transfer
        _usePaymentIntent(msg.sender, payment);
        if (payment.payee.payload.length > 0) {
            (bool success, ) = payment.payee.payeeAddress.call{value: msg.value}(payment.payee.payload);
            if(!success) revert PayeeRefusedPayment();
        } else {
            // EOA will always be able to receive the payment
            payment.payee.payeeAddress.send(msg.value);
        }
    }

    // @inheritdoc IPayments
    function payToken (
        PaymentIntent calldata payment
    ) public 
    {
        _usePaymentIntent(msg.sender, payment);
        // do a permit2 transfer
        permit2.permitTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: payment.currency,
                    amount: payment.amount
                }),
                nonce: getPaymentId(payment),
                deadline: payment.ttl
            }),
            ISignatureTransfer.SignatureTransferDetails({
                requestedAmount: payment.amount,
                to: payment.payee.payeeAddress
            }),
            msg.sender, 
            payment.permit2signature
        );
        (bool success, ) = payment.payee.payeeAddress.call(abi.encode(payment));
        if(!success) revert PayeeRefusedPayment();
    }

    // @inheritdoc IPayments
    function payTokenPreAppoved (
        PaymentIntent calldata payment
    ) public 
    {
        if(block.timestamp > payment.ttl) revert PaymentExpired();
        // this also prevent reentrancy so it must come before the transfer
        _usePaymentIntent(msg.sender, payment);
        SafeTransferLib.safeTransferFrom(payment.currency, msg.sender, payment.payee.payeeAddress, payment.amount);
        (bool success, ) = payment.payee.payeeAddress.call(abi.encode(payment));
        if(!success) revert PayeeRefusedPayment();
    }

    // @inheritdoc IPayments
    function pay(
        PaymentIntent calldata payment
    ) public payable
    {
        if(payment.currency == ETH) {
            payNative(payment);
        } else if(payment.permit2signature.length > 0) {
            payToken(payment);
        } else {
            payTokenPreAppoved(payment);
        }
    }

    // @inheritdoc IPayments
    function multiPay(
        PaymentIntent[] calldata payments
    ) public payable
    {
        for (uint i = 0; i < payments.length; i++) {
            pay(payments[i]);
        }
    }

    // @inheritdoc IPayments
    function revertPayment(address from, PaymentIntent calldata payment) public {
        if(msg.sender != payment.payee.payeeAddress) revert NotPayee();
        if(!payment.payee.canRevert) revert RevertNotAllowed();
        uint paymentId = getPaymentId(payment);
        bool flipped = paymentBitmap.toggle(uint256(uint160(from)) ^ paymentId);
        if (flipped) revert PaymentNotMade();
    }

    // @inheritdoc IPayments
    function hasPaymentBeenMade(address from, PaymentIntent calldata payment) public view returns (bool) {
        return paymentBitmap.get(uint256(uint160(from)) ^ getPaymentId(payment));
    }

    // @inheritdoc IPayments
    function getPaymentId(PaymentIntent calldata payment) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(payment)));
    }

    /// @notice Checks whether a payment has been made and sets the bit at the bit position in the bitmap at the word position
    /// @param from The address to use to make the payment 
    /// @param payment The payment
    function _usePaymentIntent(address from, PaymentIntent calldata payment) internal {
        uint paymentId = getPaymentId(payment);
        bool flipped = paymentBitmap.toggle(uint256(uint160(from)) ^ paymentId);
        if (!flipped) revert PaymentAlreadyMade();
    }
}
