pragma solidity ^0.8.21;

import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

import "./IPayments.sol";

address constant ETH = address(0);

contract Payments is IPayments {
    using SafeTransferLib for ERC20;

    // a map of payment status indexed by the receipt hash
    mapping(address payeer => mapping(uint256 payment => uint256)) paymentBitmap;
    IPermit2 permit2;

    constructor(
        address _permit2
    ) 
    {
        permit2 = IPermit2(_permit2);
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
        // call the fallback function
        // TODO: it might make sense to check payeeAddress.code.length > 0 to save gas
        (bool success, ) = payment.payee.payeeAddress.call(abi.encode(payment));
        if(!success) revert PayeeRefusedPayment();
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
        ERC20(payment.currency).safeTransferFrom(msg.sender, payment.payee.payeeAddress, payment.amount);
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

    function hasPaymentBeenMade(address from, PaymentIntent calldata payment) public view returns (bool) {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(payment);
        return paymentBitmap[from][wordPos] & (1 << bitPos) != 0;
    }

    // @inheritdoc IPayments
    function getPaymentId(PaymentIntent calldata payment) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(payment)));
    }

    /// @notice Returns the index of the bitmap and the bit position within the bitmap. 
    /// @param payment The payment to get the associated word and bit positions
    /// @return wordPos The word position or index into the nonceBitmap
    /// @return bitPos The bit position
    /// @dev The first 248 bits of the payment hash value is the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
    function bitmapPositions(PaymentIntent calldata payment) private pure returns (uint256 wordPos, uint256 bitPos) {
        uint256 id = getPaymentId(payment);
        wordPos = uint248(id >> 8);
        bitPos = uint8(id);
    }

    /// @notice Checks whether a payment has been made and sets the bit at the bit position in the bitmap at the word position
    /// @param from The address to use to make the payment 
    /// @param payment The payment
    function _usePaymentIntent(address from, PaymentIntent calldata payment) internal {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(payment);
        uint256 bit = 1 << bitPos;
        uint256 flipped = paymentBitmap[from][wordPos] ^= bit;

        if (flipped & bit == 0) revert PaymentAlreadyMade();
    }
}
