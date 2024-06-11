// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {ShopReg} from "../src/ShopReg.sol";
import {RelayReg} from "../src/RelayReg.sol";
import {AccessControl} from "../src/AccessControl.sol";

contract ShopUsersTest is Test {
    ShopReg internal s;
    uint256 internal shopId;
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
        s = new ShopReg(new RelayReg());
        clerk = 4;
        admin = 2047;
        shopId = 42;
        s.mint(shopId, addrOwner);
    }

    function testUsersRegisterOwner() public {
        vm.prank(addrOwner);
        s.registerUser(shopId, addrNewUser, clerk);
    }

    function testUsersRemove() public {
        vm.startPrank(addrOwner);
        s.registerUser(shopId, addrNewUser, clerk);
        s.removeUser(shopId, addrNewUser);
    }

    function testUsersRegisterNotAllowed() public {
        vm.prank(addrOwner);
        s.registerUser(shopId, addrNewUser, clerk);
        vm.prank(addrNewUser);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.NotAuthorized.selector, 255));
        s.registerUser(shopId, addrSomeoneElse, admin);
    }

    function testUsersRegisterByClerk() public {
        vm.prank(addrOwner);
        s.registerUser(shopId, addrNewUser, clerk);
        vm.startPrank(addrNewUser);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.NotAuthorized.selector, 255));
        s.registerUser(shopId, addrSomeoneElse, clerk);
        assertEq(s.hasEnoughPermissions(shopId, addrSomeoneElse, clerk), false);
        assertEq(s.hasEnoughPermissions(shopId, addrSomeoneElse, admin), false);
    }

    function testUsersRegisterByAdmin() public {
        vm.prank(addrOwner);
        s.registerUser(shopId, addrNewUser, admin);
        vm.startPrank(addrNewUser);
        s.registerUser(shopId, addrSomeoneElse, clerk);
        assertEq(s.hasEnoughPermissions(shopId, addrSomeoneElse, clerk), true);
        assertEq(s.hasEnoughPermissions(shopId, addrSomeoneElse, admin), false);
        s.removeUser(shopId, addrSomeoneElse);
        assertEq(s.hasEnoughPermissions(shopId, addrSomeoneElse, clerk), false);
    }

    function testTokenRegistration() public {
        (address token, uint256 tokenPk) = makeAddrAndKey("token");
        vm.prank(addrOwner);
        s.publishInviteVerifier(shopId, token);
        // new user wants to redeem the token
        bytes32 regMsg = s._getTokenMessageHash(addrNewUser);
        (uint8 sigv, bytes32 sigr, bytes32 sigs) = vm.sign(tokenPk, regMsg);
        vm.prank(addrNewUser);
        s.redeemInvite(shopId, sigv, sigr, sigs, addrNewUser);
        vm.prank(addrOwner);
        assertEq(true, s.hasEnoughPermissions(shopId, addrNewUser, clerk));
        // try to use the token twice
        vm.prank(addrSomeoneElse);
        vm.expectRevert(ShopReg.NoVerifier.selector);
        s.redeemInvite(shopId, sigv, sigr, sigs, addrSomeoneElse);
        // cant register a user twice
        (address token2, uint256 tokenPk2) = makeAddrAndKey("token2");
        vm.prank(addrOwner);
        s.publishInviteVerifier(shopId, token2);
        (sigv, sigr, sigs) = vm.sign(tokenPk2, regMsg);
        vm.prank(addrNewUser);
    }
}
