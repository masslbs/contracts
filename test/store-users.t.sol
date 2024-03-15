// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import { StoreReg } from "../src/StoreReg.sol";
import { RelayReg } from "../src/RelayReg.sol";
import { AccessControl } from "../src/AccessControl.sol";

contract StoreUsersTest is Test {
    StoreReg internal s;
    uint256 internal storeId;
    address internal addrOwner;
    address internal addrNewUser;
    uint256 pkNewUser;
    address internal addrSomeoneElse;
    uint256 internal clerk;
    uint256 internal admin;

    function setUp() public {
        addrOwner = msg.sender;
        (addrNewUser, pkNewUser) = makeAddrAndKey("newUser");
        addrSomeoneElse = address(0x01a1257382B6b9a7BDFeF762379C085Ca50F1Ca9);
        s = new StoreReg(new RelayReg());
        clerk = s.STATE_UPDATER();
        admin = 2047;
        storeId = 42;
        s.mint(storeId, addrOwner);
    }

    function testUsersRegisterOwner() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, clerk);
    }

    function testUsersRemove() public {
        vm.startPrank(addrOwner);
        s.registerUser(storeId, addrNewUser, clerk);
        s.removeUser(storeId, addrNewUser);
    }

    function testUsersRegisterNotAllowed() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, clerk);
        vm.prank(addrNewUser);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControl.NotAuthorized.selector, 255)
        );
        s.registerUser(storeId, addrSomeoneElse, admin);
    }

    function testUsersRegisterByClerk() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, clerk);
        vm.startPrank(addrNewUser);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControl.NotAuthorized.selector, 255)
        );
        s.registerUser(storeId, addrSomeoneElse, clerk);
        assertEq(s.hasEnoughPermissions(storeId, addrSomeoneElse, clerk), false);
        assertEq(s.hasEnoughPermissions(storeId, addrSomeoneElse, admin), false);
    }

    function testUsersRegisterByAdmin() public {
        vm.prank(addrOwner);
        s.registerUser(storeId, addrNewUser, admin);
        vm.startPrank(addrNewUser);
        s.registerUser(storeId, addrSomeoneElse, clerk);
        assertEq(s.hasEnoughPermissions(storeId, addrSomeoneElse, clerk), true);
        assertEq(s.hasEnoughPermissions(storeId, addrSomeoneElse, admin), false);
        s.removeUser(storeId, addrSomeoneElse);
        assertEq(s.hasEnoughPermissions(storeId, addrSomeoneElse, clerk), false);
    }

    function testTokenRegistration() public {
        (address token, uint256 tokenPk) = makeAddrAndKey("token");
        vm.prank(addrOwner);
        s.publishInviteVerifier(storeId, token);
        // new user wants to redeem the token
        bytes32 regMsg = s._getTokenMessageHash(addrNewUser);
        (uint8 sigv, bytes32 sigr, bytes32 sigs) = vm.sign(tokenPk, regMsg);
        vm.prank(addrNewUser);
        s.redeemInvite(storeId, sigv, sigr, sigs, addrNewUser);
        vm.prank(addrOwner);
        assertEq(true, s.hasEnoughPermissions(storeId, addrNewUser, clerk));
        // try to use the token twice
        vm.prank(addrSomeoneElse);
        vm.expectRevert(StoreReg.NoVerifier.selector);
        s.redeemInvite(storeId, sigv, sigr, sigs, addrSomeoneElse);
        // cant register a user twice
        (address token2, uint256 tokenPk2) = makeAddrAndKey("token2");
        vm.prank(addrOwner);
        s.publishInviteVerifier(storeId, token2);
        (sigv, sigr, sigs) = vm.sign(tokenPk2, regMsg);
        vm.prank(addrNewUser);
    }
}
