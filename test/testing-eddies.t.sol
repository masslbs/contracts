// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/testing-eddies.sol";

contract EddiesTest is Test {
  EuroDollarToken eddies;

  address alice = vm.addr(0x01);
  address bob = vm.addr(0x02);

  function setUp() public {
    eddies = new EuroDollarToken("Eddies", "EDD");
  }

  function testName() external {
    assertEq(eddies.name(), "Eddies");
  }


  function testSymbol() external {
    assertEq(eddies.symbol(), "EDD");
  }

  function testMint() public {
    eddies.mint(alice, 2e18);
    assertEq(eddies.balanceOf(alice), eddies.totalSupply());
  }

  function testBurn() public {
    eddies.mint(alice, 10e18);
    assertEq(eddies.balanceOf(alice), 10e18);

    eddies.burn(alice, 8e18);
    
    assertEq(eddies.totalSupply(), 2e18);
    assertEq(eddies.balanceOf(alice), 2e18);
  }

  function testApprove() public {
    eddies.approve(bob, 5e18);
    assertEq(eddies.allowance(address(this), bob), 5e18);
  }

  // TODO: increaseAllowance is non-standard erc20
  // function testIncreaseAllowance() external {
  //   assertEq(eddies.allowance(address(this), alice), 0);
  //   assertTrue(eddies.increaseAllowance(alice, 3e18));
  //   assertEq(eddies.allowance(address(this), alice), 3e18);
  // }

  function testTransfer() external {
    testMint();
    vm.startPrank(alice);
    eddies.transfer(bob, 0.5e18);
    assertEq(eddies.balanceOf(bob), 0.5e18);
    assertEq(eddies.balanceOf(alice), 1.5e18);
    vm.stopPrank();
  }

  function testTransferFrom() external {
    testMint();
    vm.prank(alice);
    eddies.approve(address(this), 1e18);
    uint256 amount = 0.7e18;
    assertTrue(eddies.transferFrom(alice, bob, amount));
    assertEq(eddies.allowance(alice, address(this)), 1e18-amount);
    assertEq(eddies.balanceOf(alice), 2e18-amount);
    assertEq(eddies.balanceOf(bob), amount);
  }

  // Test failures

  function testFailMintToZero() external {
    eddies.mint(address(0), 1e18);
  }

  function testFailBurnFromZero() external {
    eddies.burn(address(0), 1e18);
  }

  function testFailBurnInsufficientBalance() external {
    testMint();
    vm.prank(alice);
    eddies.burn(alice, 3e18);
  }

  function testFailApproveZeroAddress() external {
    eddies.approve(address(0), 1e18);
  }

  function testFailApproveFromZeroAddress() external {
    vm.prank(address(0));
    eddies.approve(alice, 1e18);
  }

  function testFailTransferToZeroAddress() external {
    testMint();
    vm.prank(alice);
    eddies.transfer(address(0), 1e18);
  }

  function testFailTransferFromZeroAddress() external {
    testMint();
    vm.prank(address(0));
    eddies.transfer(alice, 1e18);
  }

  function testFailTransferInsufficientbalance() external {
    testMint();
    vm.prank(alice);
    eddies.transfer(bob, 3e18);
  }

  function testFailTransferFromInsufficienApprove() external {
    testMint();
    vm.prank(alice);
    eddies.approve(address(this), 1e18);
    eddies.transferFrom(alice, bob, 2e18);
  }

  function testFailTransferFromInsufficienBalance() external {
    testMint();
    vm.prank(alice);
    eddies.approve(address(this), type(uint).max);
    
    eddies.transferFrom(alice, bob, 3e18);
  }
}