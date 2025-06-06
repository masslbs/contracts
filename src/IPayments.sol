// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

/// @notice a struct to hold the payment details
/// @member chainId The network the payment is supposed to be made on
/// @member ttl The deadline for the payment (block.timestamp)
/// @member order The hash of the order details
/// @member currency The address of the ERC20 token to be transferred
/// @member amount The amount of tokens to be transferred
/// @member payeeAddress The address that will receive the payment
/// @member isPaymentAddress Whether the payment should be forwarded with another contract call. See IPaymentEndpoint.
/// @member shopId The token id of the shop
/// @member shopSignature The signature of a merchant's relay or signer
struct PaymentRequest {
    uint256 chainId;
    uint256 ttl;
    bytes32 order;
    address currency;
    uint256 amount;
    address payeeAddress;
    bool isPaymentEndpoint;
    uint256 shopId;
    bytes shopSignature;
}

interface IPaymentSignals {
    event PaymentMade(uint256 indexed paymentId);

    error PaymentExpired();
    error InvalidPaymentAmount();
    error InvalidPaymentToken();
    error WrongChain();
    error PaymentAlreadyMade();
    error PayeeRefusedPayment();
    error PaymentNotMade();
    error NotPayee();
}

/// @title The Payments Contract
/// @notice The Payments Contract validates a PaymentIntent and forwards the payment to the payee.
interface IPaymentFunctions {
    /// @notice Makes a payment in native currency
    /// @param payment The payment details
    function payNative(PaymentRequest calldata payment) external payable;

    /// @notice Makes a payment in a ERC20 token
    /// @param payment The payment details
    function payToken(PaymentRequest calldata payment, bytes calldata permit2signature) external;

    /// @notice Makes a payment in a ERC20 token with pre-approval
    /// @param payment The payment details
    function payTokenPreApproved(PaymentRequest calldata payment) external;

    /// @notice Makes a payment
    /// @param payment The payment details
    function pay(PaymentRequest calldata payment) external payable;

    /// @notice Makes multiple payments
    /// @param payments An array of payment details
    function multiPay(PaymentRequest[] calldata payments, bytes[] calldata permit2Sigs) external payable;

    /// @notice Returns the id (hash) of the payment details
    /// @param payment The payment details
    function getPaymentId(PaymentRequest calldata payment) external pure returns (uint256);

    /// @notice Returns whether a payment has been made
    /// @param from The address to use to make the payment
    // @param payment The payment details
    function hasPaymentBeenMade(address from, PaymentRequest calldata payment) external view returns (bool);

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
    function pay(PaymentRequest calldata payment) external payable;
}

interface IPayments is IPaymentSignals, IPaymentFunctions {}
