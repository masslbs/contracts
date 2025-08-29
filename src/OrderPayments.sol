// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EfficientHashLib} from "solady/utils/EfficientHashLib.sol";

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

    /// @param hookCallData an optional call data that is passed to the receiving address after the sweep
    /// the hook call data can be anything and it is up to the receiving contract to validate it
    function sweep(ERC20 token, bytes calldata hookCallData) public {
        if (address(token) == ETH) {
            sweepEth(hookCallData);
        } else {
            sweepErc20(token, hookCallData);
        }
    }

    function sweepEth(bytes calldata hookCallData) public {
        uint256 balance = address(this).balance;
        (bool success,) = receivingAddress.call{value: balance}(hookCallData);
        require(success, "Failed to send Ether");
    }

    function sweepErc20(ERC20 token, bytes calldata hookCallData) public {
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(receivingAddress, balance);
        require(success, "Failed to transfer ERC20 tokens");
        if (hookCallData.length > 0) {
            (success, ) = receivingAddress.call(hookCallData);
            require(success, "Failed to call hook");
        }
    }
}

/// @title Creates an OrderPayment instances.
contract OrderPaymentsFactory {
    function getSalt(
        OrderPaymentBinding calldata binding
    ) public pure returns (bytes32) {
        bytes memory encodedAbi = abi.encode(binding);
        return EfficientHashLib.hash(encodedAbi);
    }

    function getBytecodeHash(
        address receivingAddress
    ) public pure returns (bytes32) {
        bytes memory bytecode = type(OrderPayment).creationCode;
        return EfficientHashLib.hash(abi.encodePacked(bytecode, abi.encode(receivingAddress)));
    }

    function getOrderPaymentAddress(
        OrderPaymentBinding calldata binding
    ) public view returns (address) {
        bytes32 hash = EfficientHashLib.hash(
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
