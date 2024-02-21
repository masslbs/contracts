import "../permit2/src/interfaces/ISignatureTransfer.sol"; 

// @notice a struct to hold the payment details
// @member ttl The deadline for the payment (block.timestamp)
// @member receipt The hash of the order details
// @member receiver The address that will receive the payment
// @member receiverCurrency The address of the ERC20 token to be transferred
// @member receiverAmount The amount of tokens to be transferred
// @member receiverData The data to be sent to the payoutAddress if it is a contract
// @member signature The signature of a merchant's relay or signer
PaymentIntent struct {
  uint256 ttl;               
  bytes32 receipt;           
  address currency;          
  uint256 amount;            
  address payable receiver;  
  bytes receiverData;      
  bytes signature;
}

// @notice A struct for holding Permit2 signature transfer data
struct Permit2SignatureTransferData {
  ISignatureTransfer.PermitTransferFrom permit;
  ISignatureTransfer.SignatureTransferDetails transferDetails;
  bytes signature;
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
  // @param p2data The permit2 signature transfer data
  function payToken (
    PaymentIntent calldata payment,
    Permit2SignatureTransferData calldata p2data
  ) external;

  // @notice Makes a payment in a ERC20 token with pre-approval
  // @param payments The payment details
  // @param tokenIn The address of the ERC20 token to be transferred
  function payTokenPreAppoved (
    PaymentIntent calldata payment,
    address tokenIn
  ) external;

  // @notice Swaps native currency for a ERC20 token and makes a payment
  // @param payments The payment details
  function swapNativeAndPay(
    PaymentIntent calldata payment,
  ) external payable;

  // @notice Swaps a ERC20 token for another ERC20 token and makes a payment
  // @param payments The payment details
  // @param signatureTransferData The permit2 signature transfer data
  function swapTokenAndPay(
    PaymentIntent calldata payment,
    Permit2SignatureTransferData calldata signatureTransferData
  ) external;

  // @notice Swaps a ERC20 token for another ERC20 token and makes a payment with pre-approval
  // @param payments The payment details
  // @param tokenIn The address of the ERC20 token to be transferred
  function swapTokenAndPayPreAppoved(
    PaymentIntent calldata payment,
    address tokenIn,
  ) external;

  // @notice Makes multiple payments in native currency
  // @param payments An array of payment details
  function multiPayNative(
    PaymentIntent[] calldata payments
  ) external;

  // @notice Makes multiple payments in a ERC20 token
  // @param payments An array of payment details
  // @param signatureTransferData The permit2 signature transfer data:
  function multiPayToken(
    PaymentIntent[] calldata payments
    Permit2SignatureTransferData calldata signatureTransferData
  ) external;

  // @notice Makes multiple payments in a ERC20 token with pre-approval
  // @param payments An array of payment details
  function multiPayTokenPreAppoved(
    PaymentIntent[] calldata payments
  ) external;

  function multiSwapAndPayNative(
    PaymentIntent[] calldata payments,
    address pt
  ) external;

  function multiSwapAndPayToken(
    PaymentIntent[] calldata payments,
    address pt,
    Permit2SignatureTransferData calldata signatureTransferData
  ) external;

  function multiSwapAndPayTokenPreAppoved(
    PaymentIntent[] calldata payments,
    address pt
  ) external;
}
