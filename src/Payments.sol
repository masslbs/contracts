import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract Payments  {
  using SafeERC20 for IERC20;

  // a map of payment status indexed by the receipt hash
  mapping(bytes32 => bool) public payments;

  // a struct to hold the payment details
  payment struct {
    uint256 ttl;          // deadline for the payment (block.timestamp)
    bytes32 receipt;      // hash of the order details
    address currency;     // address of the ERC20 token to be transferred
    uint256 amount;       // amount of tokens to be transferred
    address receiver;     // address that will receive the payment
    bytes   receiverData; // data to be sent to the payoutAddress if it is a contract
    // signature of a merchant's relay or signer
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function makePayment(payment memory p) public {
    require(p.ttl >= block.timestamp, "Payment has expired");

    // transfer the ERC20 tokens to the merchant
    IERC20(p.currency).transfer(p.merchant, p.amount);

    // if there is reciever data, call the receiver
    if (p.receiverData.length > 0) {
      (bool success, ) = p.merchant.call(p);
      require(success, "Receiver call failed");
    }

    // send any remaining tokens to the sender
    IERC20(p.currency).transfer(p.sender, IERC20(p.currency).balanceOf(address(this)));

    // just need to hash signature 
    bytes32 paymentHash = keccak256(abi.encodePacked(p.v, p.s, p.amount, p.r));

    // mark the payment as completed
    payments[paymentHash] = true;
  }
}

contract Escrow {
  constructor(address arbiter, address merchant, address refund, address currency, uint256 amount, uint256 paymentId) {
    let results = arbiter.call(abi.encodeWithSignature("isReleased(address,address,address,uint256,uint256)", merchant, currency, amount, paymentId));
    if (results) {
      // release the funds to the merchant
      IERC20(currency).transfer(merchant, amount);
    } else {
      // refund the customer
      IERC20(currency).transfer(refund, amount);
      // 
    }
  }
}
