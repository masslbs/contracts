// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/store-reg.sol";


contract StoreUsersTest is Test {
    Store internal s;
    uint256 internal storeId;
    address internal addrOwner;
    address internal addrNewUser;
    address internal addrSomeoneElse;
     bytes32 internal testHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;

    function setUp() public {
        addrOwner = msg.sender;
        // console.log("setUp owner=%a", addrOwner);
        addrNewUser = address(0x6f8e7BD90cC9AF3AA50108eaC86DE0F952e4D3Ca);
        addrSomeoneElse = address(0x01a1257382B6b9a7BDFeF762379C085Ca50F1Ca9);
        s = new Store(new RelayReg());
        storeId = s.mint(addrOwner, testHash);
    }

    function testUsersRegisterOwner() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, AccessLevel.Clerk);
    }

    function testUsersRemove() public {
        vm.startPrank(addrOwner);
        s.registerUser(storeId, addrNewUser, AccessLevel.Clerk);
        s.removeUser(storeId, addrNewUser);
    }

    function testUsersRegisterNotAllowed() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, AccessLevel.Clerk);
        vm.expectRevert("no such user");
        vm.prank(addrNewUser);
        s.registerUser(storeId, addrSomeoneElse, AccessLevel.Admin);
    }

    function testUsersRegisterByClerk() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, AccessLevel.Clerk);
        vm.startPrank(addrNewUser);
        vm.expectRevert("no such user");
        s.registerUser(storeId, addrSomeoneElse, AccessLevel.Clerk);
        assertEq(s.hasAtLeastAccess(storeId, addrSomeoneElse, AccessLevel.Clerk), false);
        assertEq(s.hasAtLeastAccess(storeId, addrSomeoneElse, AccessLevel.Admin), false);
        assertEq(s.hasAtLeastAccess(storeId, addrSomeoneElse, AccessLevel.Owner), false);
    }

    function testUsersRegisterByAdmin() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, AccessLevel.Admin);
        vm.startPrank(addrNewUser);
        s.registerUser(storeId, addrSomeoneElse, AccessLevel.Clerk);
        assertEq(s.hasAtLeastAccess(storeId, addrSomeoneElse, AccessLevel.Clerk), true);
        assertEq(s.hasAtLeastAccess(storeId, addrSomeoneElse, AccessLevel.Admin), false);
        assertEq(s.hasAtLeastAccess(storeId, addrSomeoneElse, AccessLevel.Owner), false);
        s.removeUser(storeId, addrSomeoneElse);
        assertEq(s.hasAtLeastAccess(storeId, addrSomeoneElse, AccessLevel.Clerk), false);
    }
}
