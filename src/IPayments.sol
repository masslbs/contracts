// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

/// @notice Where the payment will be sent including a possible payload
/// @member payeeAddress The address that will receive the payment
/// @member payload The payload to be sent to the payee
struct PaymentEndpointDetails {
    address payeeAddress;
    bytes payload;
    bool canRevert;
}

/// @notice a struct to hold the payment details
/// @member ttl The deadline for the payment (block.timestamp)
/// @member receipt The hash of the order details
/// @member amount The amount of tokens to be transferred
/// @member currency The address of the ERC20 token to be transferred
/// @member payee The address that will receive the payment
/// @member shopId The id of thes shop
/// @member signature The signature of a merchant's relay or signer
/// @member permit2signature The signature of a permit2
struct PaymentIntent {
    uint256 ttl;
    bytes32 receipt;
    address currency;
    uint256 amount;
    PaymentEndpointDetails payee;
    uint256 shopId;
    bytes shopSignature; // signature does not need to equal the payee's address
    bytes permit2signature;
}

/// @title The Payments Contract
/// @notice The Payments Contract validates a PaymentIntent and forwards the payment to the payee.
interface IPayments {
    error PaymentExpired();
    error InvalidPaymentAmount();
    error InvalidPaymentToken();
    error PaymentAlreadyMade();
    error PayeeRefusedPayment();
    // used to revert payments
    error PaymentNotMade();
    error NotPayee();
    error RevertNotAllowed();

    /// @notice Makes a payment in native currency
    /// @param payment The payment details
    function payNative(PaymentIntent calldata payment) external payable;

    /// @notice Makes a payment in a ERC20 token
    /// @param payment The payment details
    function payToken(PaymentIntent calldata payment) external;

    /// @notice Makes a payment in a ERC20 token with pre-approval
    /// @param payment The payment details
    function payTokenPreApproved(PaymentIntent calldata payment) external;

    /// @notice Makes a payment
    /// @param payment The payment details
    function pay(PaymentIntent calldata payment) external payable;

    /// @notice Makes multiple payments
    /// @param payments An array of payment details
    function multiPay(PaymentIntent[] calldata payments) external payable;

    /// @notice Returns the id (hash) of the payment details
    /// @param payment The payment details
    function getPaymentId(PaymentIntent calldata payment) external pure returns (uint256);

    /// @notice Returns whether a payment has been made
    /// @param from The address to use to make the payment
    // @param payment The payment details
    function hasPaymentBeenMade(address from, PaymentIntent calldata payment) external view returns (bool);

    // // @notice Swaps tokens and makes a payment
    // // @param payment The payment details
    // // @param commands The commands to be executed by the universal router
    // function swapAndPay(
    //   PaymentIntent calldata payment,
    //   bytes calldata commands,
    // ) external payable;
    //
    // // @notice Swaps tokens and make multiple payments
    // // @param commands The commands to be executed by the universal router
    // function swapAndMultiPay(
    //   PaymentIntent calldata payment,
    //   bytes calldata commands,
    // ) external payable;
}

/// @notice A paymentEndpoint is a contract that can receive payments from the payment contract
interface IPaymentEndpoint {
    /// @notice The function that is called by the payment contract when a transfer is made
    /// @param payment The payment details
    function pay(PaymentIntent calldata payment) external payable;
}
