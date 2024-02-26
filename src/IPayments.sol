// @notice a struct to hold the payment details
// @member ttl The deadline for the payment (block.timestamp)
// @member receipt The hash of the order details
// @member amount The amount of tokens to be transferred
// @member currency The address of the ERC20 token to be transferred
// @member payee The address that will receive the payment
// @member data The data to be sent to the payoutAddress if it is a contract
// @member signature The signature of a merchant's relay or signer
struct PaymentIntent {
  uint256 ttl;               
  bytes32 receipt;           
  address currency;          
  uint256 amount;
  address payable payee;
  bytes data;      
  bytes signature; // signature does not need to equal the payee's address
}

// @title The Payments Contract
// @notice Function for making payments and swapping tokens
interface IPayments {
  // @notice Makes a payment in native currency
  // @param PaymentIntent The payment details
  function payNative(
    PaymentIntent calldata payment
  ) external payable;

  // @notice Makes a payment in a ERC20 token
  // @param payments The payment details
  // @param permit2signature The permit2 signature
  function payToken (
    PaymentIntent calldata payment,
    bytes calldata permit2signature
  ) external;

  // @notice Makes a payment in a ERC20 token with pre-approval
  // @param payments The payment details
  // @param paymentToken The address of the ERC20 token to be transferred
  function payTokenPreAppoved (
    PaymentIntent calldata payment,
    address paymentToken
  ) external;

  // @notice Swaps native currency for a ERC20 token and makes a payment
  // @param payments The payment details
  function swapNativeAndPay(
    PaymentIntent calldata payment
  ) external payable;

  // @notice Swaps a ERC20 token for another ERC20 token and makes a payment
  // @param payments The payment details
  // @param permit2signature The permit2 signature
  function swapTokenAndPay(
    PaymentIntent calldata payment,
    bytes calldata permit2signature
  ) external;

  // @notice Swaps a ERC20 token for another ERC20 token and makes a payment with pre-approval
  // @param payments The payment details
  // @param paymentToken The address of the ERC20 token to be transferred
  function swapTokenAndPayPreAppoved(
    PaymentIntent calldata payment,
    address paymentToken
  ) external;

  // @notice Makes multiple payments in native currency
  // @param payments An array of payment details
  function multiPayNative(
    PaymentIntent[] calldata payments
  ) external payable;

  // @notice Makes multiple payments in a ERC20 token
  // @param payments An array of payment details
  // @param permit2signature The permit2 signature
  function multiPayToken(
    PaymentIntent[] calldata payments,
    bytes calldata permit2signature
  ) external;

  // @notice Makes multiple payments in a ERC20 token with pre-approval
  // @param payments An array of payment details
  function multiPayTokenPreAppoved(
    PaymentIntent[] calldata payments
  ) external;

  // @notice Swaps native currency for a ERC20 token and makes multiple payments
  // @param payments An array of payment details
  // @param pt The address of the ERC20 token to be transferred
  function multiSwapAndPayNative(
    PaymentIntent[] calldata payments,
    address paymentToken
  ) external payable;

  // @notice Swaps a ERC20 token for another ERC20 token and makes multiple payments
  // @param payments An array of payment details
  // @param permit2signature The permit2 signature
  function multiSwapAndPayToken(
    PaymentIntent[] calldata payments,
    address paymentToken,
    bytes calldata permit2signature
  ) external;

  // @notice Swaps a ERC20 token for another ERC20 token and makes multiple payments with pre-approval
  // @param payments An array of payment details
  function multiSwapAndPayTokenPreAppoved(
    PaymentIntent[] calldata payments,
    address paymentToken
  ) external;
}
