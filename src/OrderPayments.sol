// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";

address constant ETH = address(0);

/// used as salt for creating an OrderPayment Contract
struct OrderPaymentBinding {
    uint256 chainId;
    uint256 shopId;
    uint256 orderId;
    /// Merchant (or escrow) account receiving the payment
    address payable receivingAddress;
}

/// @title A contract for an order with functions that sweeps ERC20's and Eth from the payment address to the receiving address
/// @notice  ERC20 sweeps can fail depending on the ERC20 implementation
contract OrderPayment {
    address payable receivingAddress;

    constructor(address payable _receivingAddress) {
        receivingAddress = _receivingAddress;
    }

    function sweep(ERC20 token) public {
        if (address(token) == ETH) {
            sweepEth();
        } else {
            sweepERC20(token);
        }
    }

    function sweepEth() public {
        uint256 balance = address(this).balance;
        receivingAddress.transfer(balance);
    }

    function sweepERC20(ERC20 token) public {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(receivingAddress, balance);
    }
}

/// @title Creates an OrderPayment instances.
contract OrderPaymentsFactory {
    function getSalt(
        OrderPaymentBinding calldata binding
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(binding));
    }

    function getBytecodeHash(
        address receivingAddress
    ) public pure returns (bytes32) {
        bytes memory bytecode = type(OrderPayment).creationCode;
        return keccak256(abi.encodePacked(bytecode, abi.encode(receivingAddress)));
    }

    function getOrderPaymentAddress(
        OrderPaymentBinding calldata binding
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                getSalt(binding), // salt
                bytes32(getBytecodeHash(binding.receivingAddress))
            )
        );

        return address(uint160(uint256(hash)));
    }

    function deployOrderPayment (
        OrderPaymentBinding calldata binding
    ) public {
        new OrderPayment{salt: getSalt(binding)}(binding.receivingAddress);
    }
}
