pragma solidity ^0.8.21;

// @notice Where the payment will be sent including a possible payload
// @member payeeAddress The address that will receive the payment
// @member payload The payload to be sent to the payee
struct PaymentEndpoint {
  address payeeAddress;
  bytes payload;
}

// @notice a struct to hold the payment details
// @member ttl The deadline for the payment (block.timestamp)
// @member receipt The hash of the order details
// @member amount The amount of tokens to be transferred
// @member currency The address of the ERC20 token to be transferred
// @member payee The address that will receive the payment
// @member shopId The id of thes shop 
// @member signature The signature of a merchant's relay or signer
// @member permit2signature The signature of a permit2
struct PaymentIntent {
  uint256 ttl;               
  bytes32 receipt;           
  address currency;          
  uint256 amount;
  PaymentEndpoint payee;
  uint256 shopId;
  bytes shopSignature; // signature does not need to equal the payee's address
  bytes permit2signature;
}


// @title The Payments Contract
// @notice The Payments Contract validates a PaymentIntent and forwards the payment to the payee.
interface IPayments {
  error PaymentExpired();
  error InvalidPaymentAmount();
  error InvalidPaymentToken();
  error PaymentAlreadyMade();
  error PayeeRefusedPayment();


  // @notice Makes a payment in native currency
  // @param PaymentIntent The payment details
  function payNative(
    PaymentIntent calldata payment
  ) external payable;

  // @notice Makes a payment in a ERC20 token
  // @param payments The payment details
  function payToken (
    PaymentIntent calldata payment
  ) external;

  // @notice Makes a payment in a ERC20 token with pre-approval
  // @param payments The payment details
  function payTokenPreAppoved (
    PaymentIntent calldata payment
  ) external;

  // @notice Makes a payment
  // @param PaymentIntent The payment details
  function pay(
    PaymentIntent calldata payment
  ) external payable;

  // @notice Makes multiple payments
  // @param payments An array of payment details
  function multiPay(
    PaymentIntent[] calldata payments
  ) external payable;

  // @notice Returns the id (hash) of the payment details
  function getPaymentId(
    PaymentIntent calldata payment
  ) external pure returns (uint256);

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
