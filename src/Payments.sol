import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "permit2/src/interfaces/IPermit2.sol";

import "./IPayments.sol";

contract Payments is IPayments {
  // Wrappers around ERC-20 operations that throw on failure (when the token
  // contract returns false). Tokens that return no value (and instead revert or
  // throw on failure) are also supported, non-reverting calls are assumed to be
  // successful.
  using SafeERC20 for IERC20;

  // a map of payment status indexed by the receipt hash
  IPermit2 public immutable permit2;

  constructor(
    address _permit2
  ) {
    permit2 = IPermit2(_permit2);
  }
  // @inheritdoc IPayments
  function payNative(
    PaymentIntent calldata payment
  ) external payable
  {
    require(block.timestamp <= payment.ttl, "Payment has expired");
    require(msg.value == payment.amount, "Invalid payment amount");
    payment.payee.transfer(msg.value);
  }

  // @inheritdoc IPayments
  function payToken (
    PaymentIntent calldata payment,
    bytes calldata permit2signature
  ) external 
  {
    require(block.timestamp <= payment.ttl, "Payment has expired");
  }

  // @inheritdoc IPayments
  function payTokenPreAppoved (
    PaymentIntent calldata payment,
    address paymentToken
  ) external 
  {
    require(block.timestamp <= payment.ttl, "Payment has expired");
    IERC20(paymentToken).safeTransferFrom(msg.sender, payment.payee, payment.amount);
  }

  // @inheritdoc IPayments
  function swapNativeAndPay(
    PaymentIntent calldata payment
  ) external payable 
  {
    require(block.timestamp <= payment.ttl, "Payment has expired");
    require(msg.value == payment.amount, "Invalid payment amount");
    payment.payee.transfer(msg.value);
  }

  // @inheritdoc IPayments
  function swapTokenAndPay(
    PaymentIntent calldata payment,
    bytes calldata permit2signature
  ) external 
  {
    require(block.timestamp <= payment.ttl, "Payment has expired");
  }

  // @inheritdoc IPayments
  function swapTokenAndPayPreAppoved(
    PaymentIntent calldata payment,
    address paymentToken
  ) external 
  {
    require(block.timestamp <= payment.ttl, "Payment has expired");
    IERC20(paymentToken).safeTransferFrom(msg.sender, payment.payee, payment.amount);
  }

  // @inheritdoc IPayments
  function multiPayNative(
    PaymentIntent[] calldata payments
  ) external payable
  {
    for (uint i = 0; i < payments.length; i++) {
      require(block.timestamp <= payments[i].ttl, "Payment has expired");
      require(msg.value == payments[i].amount, "Invalid payment amount");
      payments[i].payee.transfer(msg.value);
    }
  }

  // @inheritdoc IPayments
  function multiPayToken(
    PaymentIntent[] calldata payments,
    bytes calldata permit2signature
  ) external 
  {
    for (uint i = 0; i < payments.length; i++) {
      require(block.timestamp <= payments[i].ttl, "Payment has expired");
    }
  }

  // @inheritdoc IPayments
  function multiPayTokenPreAppoved(
    PaymentIntent[] calldata payments
  ) external 
  {
    for (uint i = 0; i < payments.length; i++) {
      require(block.timestamp <= payments[i].ttl, "Payment has expired");
      IERC20(payments[i].currency).safeTransferFrom(msg.sender, payments[i].payee, payments[i].amount);
    }
  }

  // @inheritdoc IPayments
  function multiSwapAndPayNative(
    PaymentIntent[] calldata payments,
    address paymentToken
  ) external payable
  {
    for (uint i = 0; i < payments.length; i++) {
      require(block.timestamp <= payments[i].ttl, "Payment has expired");
      require(msg.value == payments[i].amount, "Invalid payment amount");
      payments[i].payee.transfer(msg.value);
    }
  }

  // @inheritdoc IPayments
  function multiSwapAndPayToken(
    PaymentIntent[] calldata payments,
    address paymentToken,
    bytes calldata permit2signature
  ) external 
  {
    for (uint i = 0; i < payments.length; i++) {
      require(block.timestamp <= payments[i].ttl, "Payment has expired");
    }
  }

  // @inheritdoc IPayments
  function multiSwapAndPayTokenPreAppoved(
    PaymentIntent[] calldata payments,
    address paymentToken
  ) external 
  {
    for (uint i = 0; i < payments.length; i++) {
      require(block.timestamp <= payments[i].ttl, "Payment has expired");
      IERC20(paymentToken).safeTransferFrom(msg.sender, payments[i].payee, payments[i].amount);
    }
  }
}
