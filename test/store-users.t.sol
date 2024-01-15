// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "../src/store-reg.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";


contract StoreUsersTest is Test {
    StoreReg internal s;
    uint256 internal storeId;
    address internal addrOwner;
    address internal addrNewUser;
    uint256 pkNewUser;
    address internal addrSomeoneElse;
    bytes32 internal testHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;

    function setUp() public {
        addrOwner = msg.sender;
        // console.log("setUp owner=%a", addrOwner);
        (addrNewUser, pkNewUser) = makeAddrAndKey("newUser");
        addrSomeoneElse = address(0x01a1257382B6b9a7BDFeF762379C085Ca50F1Ca9);
        s = new StoreReg(new RelayReg());
        storeId = 42;
        s.registerStore(storeId, addrOwner, testHash);
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

    function testTokenRegistration() public {
        (address token, uint256 tokenPk) = makeAddrAndKey("token");
        vm.prank(addrOwner);
        s.registrationTokenPublish(storeId, token);
        // new user wants to redeem the token
        bytes32 regMsg = s.getTokenMessageHash(addrNewUser);
        (uint8 sigv, bytes32 sigr, bytes32 sigs) = vm.sign(tokenPk, regMsg);
        vm.prank(addrNewUser);
        s.regstrationTokenRedeem(storeId, sigv, sigr, sigs, addrNewUser);
        vm.prank(addrOwner);
        assertEq(true, s.hasAtLeastAccess(storeId, addrNewUser, AccessLevel.Clerk));
        // try to use the token twice
        vm.prank(addrSomeoneElse);
        vm.expectRevert("no such token");
        s.regstrationTokenRedeem(storeId, sigv, sigr, sigs, addrSomeoneElse);
        // cant register a user twice
        (address token2, uint256 tokenPk2) = makeAddrAndKey("token2");
        vm.prank(addrOwner);
        s.registrationTokenPublish(storeId, token2);
        (sigv, sigr, sigs) = vm.sign(tokenPk2, regMsg);
        vm.prank(addrNewUser);
        vm.expectRevert("already registered");
        s.regstrationTokenRedeem(storeId, sigv, sigr, sigs, addrNewUser);
    }
}
