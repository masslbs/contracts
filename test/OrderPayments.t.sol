// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {ERC20Mock} from "openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import "../src/OrderPayments.sol";

contract OrderPaymentsFactoryTest is Test {
    OrderPaymentsFactory factory;
    ERC20Mock mockToken;
    address payable merchant;
    address payable customer;

    OrderPaymentBinding binding;

    function setUp() public {
        factory = new OrderPaymentsFactory();
        mockToken = new ERC20Mock();
        merchant = payable(makeAddr("merchant"));
        customer = payable(makeAddr("customer"));

        binding = OrderPaymentBinding({
            chainId: 1,
            shopId: 123,
            orderId: 456,
            paymentAddress: merchant
        });
    }

    function test_getSalt() public {
        bytes32 salt = factory.getSalt(binding);
        bytes32 expectedSalt = keccak256(abi.encode(binding));
        assertEq(salt, expectedSalt);
    }

    function test_getSalt_DifferentBindingsProduceDifferentSalts() public {
        OrderPaymentBinding memory binding2 = OrderPaymentBinding({
            chainId: 1,
            shopId: 123,
            orderId: 457, // different order ID
            paymentAddress: merchant
        });

        bytes32 salt1 = factory.getSalt(binding);
        bytes32 salt2 = factory.getSalt(binding2);
        assertTrue(salt1 != salt2);
    }

    function test_getOrderPaymentAddress() public {
        address predictedAddress = factory.getOrderPaymentAddress(binding);

        // Deploy the contract and verify the address matches
        factory.deployOrderPayment(binding);

        // The predicted address should match the actual deployed address
        assertTrue(predictedAddress.code.length > 0);
    }

    function test_deployOrderPayment() public {
        address predictedAddress = factory.getOrderPaymentAddress(binding);

        // Deploy the contract
        factory.deployOrderPayment(binding);

        // Verify the contract was deployed
        assertTrue(predictedAddress.code.length > 0);

        // Verify the contract is an OrderPayment instance
        OrderPayment orderPayment = OrderPayment(predictedAddress);
        // Contract should exist and be callable
        vm.expectCall(predictedAddress, abi.encodeWithSelector(OrderPayment.sweepEth.selector));
        orderPayment.sweepEth();
    }

    function test_deployOrderPayment_CannotDeployTwice() public {
        // Deploy once
        factory.deployOrderPayment(binding);

        // Try to deploy again - should revert
        vm.expectRevert();
        factory.deployOrderPayment(binding);
    }

    function test_deployOrderPayment_DifferentBindingsDeployToDifferentAddresses() public {
        OrderPaymentBinding memory binding2 = OrderPaymentBinding({
            chainId: 1,
            shopId: 123,
            orderId: 457,
            paymentAddress: merchant
        });

        address addr1 = factory.getOrderPaymentAddress(binding);
        address addr2 = factory.getOrderPaymentAddress(binding2);

        assertTrue(addr1 != addr2);

        factory.deployOrderPayment(binding);
        factory.deployOrderPayment(binding2);

        assertTrue(addr1.code.length > 0);
        assertTrue(addr2.code.length > 0);
    }
}

contract OrderPaymentTest is Test {
    OrderPayment orderPayment;
    ERC20Mock mockToken;
    address payable merchant;
    address payable customer;

    function setUp() public {
        merchant = payable(makeAddr("merchant"));
        customer = payable(makeAddr("customer"));
        orderPayment = new OrderPayment(merchant);
        mockToken = new ERC20Mock();

        // Fund the customer for testing
        vm.deal(customer, 10 ether);
        mockToken.mint(customer, 1000 ether);
    }

    function test_constructor() public {
        OrderPayment newOrderPayment = new OrderPayment(merchant);
        // Contract should be deployed successfully
        assertTrue(address(newOrderPayment) != address(0));
    }

    function test_sweepEth() public {
        uint256 amount = 1 ether;

        // Fund the order payment contract
        vm.deal(address(orderPayment), amount);

        uint256 merchantBalanceBefore = merchant.balance;
        uint256 contractBalanceBefore = address(orderPayment).balance;

        assertEq(contractBalanceBefore, amount);

        // Sweep ETH
        orderPayment.sweepEth();

        uint256 merchantBalanceAfter = merchant.balance;
        uint256 contractBalanceAfter = address(orderPayment).balance;

        assertEq(contractBalanceAfter, 0);
        assertEq(merchantBalanceAfter, merchantBalanceBefore + amount);
    }

    function test_sweepEth_EmptyContract() public {
        uint256 merchantBalanceBefore = merchant.balance;

        // Contract has no ETH
        assertEq(address(orderPayment).balance, 0);

        // Sweep should not revert but also not change balances
        orderPayment.sweepEth();

        assertEq(address(orderPayment).balance, 0);
        assertEq(merchant.balance, merchantBalanceBefore);
    }

    function test_sweepERC20() public {
        uint256 amount = 100 ether;

        // Transfer tokens to the order payment contract
        vm.prank(customer);
        mockToken.transfer(address(orderPayment), amount);

        uint256 merchantBalanceBefore = mockToken.balanceOf(merchant);
        uint256 contractBalanceBefore = mockToken.balanceOf(address(orderPayment));

        assertEq(contractBalanceBefore, amount);

        // Sweep ERC20
        orderPayment.sweepERC20(mockToken);

        uint256 merchantBalanceAfter = mockToken.balanceOf(merchant);
        uint256 contractBalanceAfter = mockToken.balanceOf(address(orderPayment));

        assertEq(contractBalanceAfter, 0);
        assertEq(merchantBalanceAfter, merchantBalanceBefore + amount);
    }

    function test_sweepERC20_EmptyContract() public {
        uint256 merchantBalanceBefore = mockToken.balanceOf(merchant);

        // Contract has no tokens
        assertEq(mockToken.balanceOf(address(orderPayment)), 0);

        // Sweep should not revert but also not change balances
        orderPayment.sweepERC20(mockToken);

        assertEq(mockToken.balanceOf(address(orderPayment)), 0);
        assertEq(mockToken.balanceOf(merchant), merchantBalanceBefore);
    }

    function test_sweepERC20_WithETHAddress() public {
        uint256 amount = 2 ether;

        // Fund the contract with ETH
        vm.deal(address(orderPayment), amount);

        uint256 merchantBalanceBefore = merchant.balance;

        // Create a mock ERC20 with ETH address (address(0))
        ERC20 ethToken = ERC20(ETH);

        // This should call sweepEth internally
        orderPayment.sweepERC20(ethToken);

        uint256 merchantBalanceAfter = merchant.balance;

        assertEq(address(orderPayment).balance, 0);
        assertEq(merchantBalanceAfter, merchantBalanceBefore + amount);
    }

    function test_sweepERC20_CanBeCalledByAnyone() public {
        uint256 amount = 100 ether;

        // Transfer tokens to the order payment contract
        vm.prank(customer);
        mockToken.transfer(address(orderPayment), amount);

        // Random address calls sweep
        address randomUser = makeAddr("random");
        vm.prank(randomUser);
        orderPayment.sweepERC20(mockToken);

        // Tokens should still go to merchant
        assertEq(mockToken.balanceOf(merchant), amount);
        assertEq(mockToken.balanceOf(address(orderPayment)), 0);
    }

    function test_sweepEth_CanBeCalledByAnyone() public {
        uint256 amount = 1 ether;

        // Fund the order payment contract
        vm.deal(address(orderPayment), amount);

        // Random address calls sweep
        address randomUser = makeAddr("random");
        vm.prank(randomUser);
        orderPayment.sweepEth();

        // ETH should still go to merchant
        assertEq(merchant.balance, amount);
        assertEq(address(orderPayment).balance, 0);
    }

    function test_fuzz_sweepEth(uint256 amount) public {
        // Bound the amount to reasonable values
        amount = bound(amount, 0, 100 ether);

        // Fund the contract
        vm.deal(address(orderPayment), amount);

        uint256 merchantBalanceBefore = merchant.balance;

        orderPayment.sweepEth();

        assertEq(address(orderPayment).balance, 0);
        assertEq(merchant.balance, merchantBalanceBefore + amount);
    }

    function test_fuzz_sweepERC20(uint256 amount) public {
        // Bound the amount to reasonable values
        amount = bound(amount, 0, type(uint128).max);

        // Mint tokens to customer and transfer to contract
        mockToken.mint(customer, amount);
        vm.prank(customer);
        mockToken.transfer(address(orderPayment), amount);

        uint256 merchantBalanceBefore = mockToken.balanceOf(merchant);

        orderPayment.sweepERC20(mockToken);

        assertEq(mockToken.balanceOf(address(orderPayment)), 0);
        assertEq(mockToken.balanceOf(merchant), merchantBalanceBefore + amount);
    }
}

contract OrderPaymentsIntegrationTest is Test {
    OrderPaymentsFactory factory;
    ERC20Mock mockToken;
    address payable merchant;
    address payable customer;

    function setUp() public {
        factory = new OrderPaymentsFactory();
        mockToken = new ERC20Mock();
        merchant = payable(makeAddr("merchant"));
        customer = payable(makeAddr("customer"));

        // Fund the customer
        vm.deal(customer, 10 ether);
        mockToken.mint(customer, 1000 ether);
    }

    function test_fullWorkflow() public {
        // Create binding
        OrderPaymentBinding memory binding = OrderPaymentBinding({
            chainId: 1,
            shopId: 123,
            orderId: 456,
            paymentAddress: merchant
        });

        // Get predicted address
        address predictedAddress = factory.getOrderPaymentAddress(binding);

        // Customer sends ETH and tokens to the predicted address
        vm.startPrank(customer);
        payable(predictedAddress).transfer(1 ether);
        mockToken.transfer(predictedAddress, 100 ether);
        vm.stopPrank();

        // Verify funds are at the predicted address
        assertEq(predictedAddress.balance, 1 ether);
        assertEq(mockToken.balanceOf(predictedAddress), 100 ether);

        // Deploy the contract
        factory.deployOrderPayment(binding);

        // Get the order payment instance
        OrderPayment orderPayment = OrderPayment(predictedAddress);

        // Sweep funds
        uint256 merchantEthBefore = merchant.balance;
        uint256 merchantTokensBefore = mockToken.balanceOf(merchant);

        orderPayment.sweepEth();
        orderPayment.sweepERC20(mockToken);

        // Verify funds were swept to merchant
        assertEq(merchant.balance, merchantEthBefore + 1 ether);
        assertEq(mockToken.balanceOf(merchant), merchantTokensBefore + 100 ether);
        assertEq(predictedAddress.balance, 0);
        assertEq(mockToken.balanceOf(predictedAddress), 0);
    }

    function test_multipleOrders() public {
        // Create multiple bindings
        OrderPaymentBinding memory binding1 = OrderPaymentBinding({
            chainId: 1,
            shopId: 123,
            orderId: 456,
            paymentAddress: merchant
        });

        OrderPaymentBinding memory binding2 = OrderPaymentBinding({
            chainId: 1,
            shopId: 123,
            orderId: 457,
            paymentAddress: merchant
        });

        // Get predicted addresses
        address addr1 = factory.getOrderPaymentAddress(binding1);
        address addr2 = factory.getOrderPaymentAddress(binding2);

        // Verify addresses are different
        assertTrue(addr1 != addr2);

        // Send different amounts to each
        vm.startPrank(customer);
        payable(addr1).transfer(1 ether);
        payable(addr2).transfer(2 ether);
        mockToken.transfer(addr1, 100 ether);
        mockToken.transfer(addr2, 200 ether);
        vm.stopPrank();

        // Deploy contracts
        factory.deployOrderPayment(binding1);
        factory.deployOrderPayment(binding2);

        // Sweep funds from both
        uint256 merchantEthBefore = merchant.balance;
        uint256 merchantTokensBefore = mockToken.balanceOf(merchant);

        OrderPayment(addr1).sweepEth();
        OrderPayment(addr1).sweepERC20(mockToken);
        OrderPayment(addr2).sweepEth();
        OrderPayment(addr2).sweepERC20(mockToken);

        // Verify total funds were swept
        assertEq(merchant.balance, merchantEthBefore + 3 ether);
        assertEq(mockToken.balanceOf(merchant), merchantTokensBefore + 300 ether);
    }
}
