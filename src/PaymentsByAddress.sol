// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "solady/src/tokens/ERC20.sol";
import "./Payments.sol";

import "forge-std/console.sol";

/// @title Sweeps ERC20's and Eth from the payment address to the merchants address
/// @notice  ERC20 sweeps can fail depending on the ERC20 implementation
contract SweepPayment {
    constructor(PaymentRequest memory payment, address payable refund, Payments paymentContract) payable {
        if (payment.currency == address(0)) {
            // if we are transfering ether
            uint256 balance = address(this).balance;
            if (balance < payment.amount) {
                refund.call{value: balance}("");
            } else {
                if (balance > payment.amount) {
                    // overpayment
                    refund.call{value: balance - payment.amount}("");
                }
                // pay the mechant
                try paymentContract.payNative{value: payment.amount}(payment) {
                    // do nothing
                } catch {
                    // refund the amount if payNative fails
                    refund.call{value: payment.amount}("");
                }
            }
        } else {
            ERC20 erc20 = ERC20(payment.currency);
            // if we are transfering an erc20
            uint256 balance = erc20.balanceOf(address(this));
            // not enough was sent so return what we have
            if (balance < payment.amount) {
                erc20.transfer(refund, balance);
            } else {
                if (balance > payment.amount) {
                    // overpayment
                    erc20.transfer(refund, balance - payment.amount);
                }
                erc20.approve(address(paymentContract), payment.amount);
                // pay the mechant
                try paymentContract.payTokenPreApproved(payment) {
                    // do nothing
                } catch {
                    // refund the amount if the payment failed
                    erc20.transfer(refund, balance);
                }
            }
        }
        // need to prevent solidity from returning code
        assembly {
            stop()
        }
    }
}

/// @title Provides functions around payments addresses
contract PaymentsByAddress is Payments {
    event SweepFailed(PaymentRequest payment);

    constructor(IPermit2 permit2) Payments(permit2){
    }

    function getBytecode(PaymentRequest calldata payment, address refund) public view returns (bytes memory) {
        bytes memory bytecode = type(SweepPayment).creationCode;
        return abi.encodePacked(bytecode, abi.encode(payment, refund, this));
    }

    /// @notice Calulates the payament address given the following parameters
    /// @return The payment address
    function getPaymentAddress(PaymentRequest calldata payment, address refund) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                payment.order, // salt; the receipt hash should be unique
                keccak256(getBytecode(payment, refund))
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /// @notice Given the parameters used to generate a payement address, this function will forward the payment to the merchant's address.
    function processPayment(PaymentRequest calldata payment, address payable refund) public {
        try new SweepPayment{salt: payment.order}(payment, refund, this) {
            // do nothing;
        } catch (bytes memory reason) {
            emit SweepFailed(payment);
        }
    }

    /// @notice this does a batched call to `processPayment`
    function batch(PaymentRequest[] calldata payments, address payable[] calldata refunds) public {
        for (uint256 i = 0; i < payments.length; i++) {
            processPayment(payments[i], refunds[i]);
        }
    }
}
