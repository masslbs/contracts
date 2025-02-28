// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {AccessControl} from "../src/AccessControl.sol";

contract MockAccessControlNFT is AccessControl {
    uint8 internal permissionForTestFunction = 66;

    constructor() {}

    function mint(uint256 _id, address _addr) public {
        _mint(_addr, _id);
    }

    function name() public pure override returns (string memory) {
        return "RelayRegestry";
    }

    function symbol() public pure override returns (string memory) {
        return "RR";
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }

    function addUser(uint256 id, address user, uint256 perms) public {
        _addUser(id, user, perms);
    }

    function removeUser(uint256 id, address user, uint256 perms) public {
        _removeUser(id, user);
    }

    function addPermission(uint256 id, address user, uint8 perm) public {
        _addPermission(id, user, perm);
    }

    function removePermission(uint256 id, address user, uint8 perm) public {
        _removePermission(id, user, perm);
    }
}

contract AccessControlTest is Test {
    MockAccessControlNFT internal ac;
    uint256 internal constant ALL_PERMS = type(uint256).max;
    uint256 internal constant shop_id = 1;
    address internal user = address(0xff);

    event UserAdded(uint256 indexed shopId, address user, uint256 permissions);
    event UserRemoved(uint256 indexed shopId, address users);
    event PermissionAdded(uint256 indexed shopId, address user, uint8 permission);
    event PermissionRemoved(uint256 indexed shopId, address user, uint8 permission);

    function setUp() public {
        ac = new MockAccessControlNFT();
        ac.mint(shop_id, address(this));
    }

    function test_ownerShouldAlwaysHavePermission() public {
        assertTrue(ac.hasEnoughPermissions(shop_id, address(this), 0));
        assertTrue(ac.hasPermission(shop_id, address(this), 1));
        assertTrue(ac.hasPermission(shop_id, address(this), 0xff));
    }

    function test_ownerShouldAlwaysHaveEnoughPermissions() public {
        assertTrue(ac.hasEnoughPermissions(shop_id, address(this), 0));
        assertTrue(ac.hasEnoughPermissions(shop_id, address(this), 1));
        assertTrue(ac.hasEnoughPermissions(shop_id, address(this), ALL_PERMS));
    }

    function test_shouldNotHavePerm() public {
        for (uint8 i = 0; i < 0xff; i++) {
            assertFalse(ac.hasPermission(shop_id, user, i));
        }
    }

    function test_shouldNotHaveEnoughPerms() public {
        assertTrue(ac.hasEnoughPermissions(shop_id, user, 0));
        assertFalse(ac.hasEnoughPermissions(shop_id, user, 1));
        assertFalse(ac.hasEnoughPermissions(shop_id, user, ALL_PERMS));
    }

    function test_newUserShouldEmit() public {
        vm.expectEmit();
        emit UserAdded(shop_id, user, ALL_PERMS);
        ac.addUser(shop_id, user, ALL_PERMS);
    }

    function test_removedUserShouldEmit() public {
        ac.addUser(shop_id, user, ALL_PERMS);
        vm.expectEmit();
        emit UserRemoved(shop_id, user);
        ac.removeUser(shop_id, user, ALL_PERMS);
    }

    function test_shouldHavePerms() public {
        ac.addUser(shop_id, user, ALL_PERMS);
        for (uint8 i = 0; i < 0xff; i++) {
            assertTrue(ac.hasPermission(shop_id, user, i));
        }
    }

    function test_shouldHaveEnoughPerms() public {
        ac.addUser(shop_id, user, ALL_PERMS);
        assertTrue(ac.hasEnoughPermissions(shop_id, user, 0));
        assertTrue(ac.hasEnoughPermissions(shop_id, user, 1));
        assertTrue(ac.hasEnoughPermissions(shop_id, user, ALL_PERMS));
    }

    function test_addingPermissionShouldEmit() public {
        uint8 perm = 1;
        vm.expectEmit();
        emit PermissionAdded(shop_id, user, perm);
        ac.addPermission(shop_id, user, perm);
    }

    function test_addedPermissionShouldExist() public {
        uint8 perm = 1;
        ac.addPermission(shop_id, user, perm);
        assertTrue(ac.hasPermission(shop_id, user, perm));
    }

    function test_removePermissionShouldEmit() public {
        uint8 perm = 1;
        ac.addPermission(shop_id, user, perm);
        vm.expectEmit();
        emit PermissionRemoved(shop_id, user, perm);
        ac.removePermission(shop_id, user, perm);
    }

    function test_removedPermissionShouldNotExist() public {
        uint8 perm = 1;
        ac.addPermission(shop_id, user, perm);
        ac.removePermission(shop_id, user, perm);
        assertFalse(ac.hasPermission(shop_id, user, perm));
    }

    function test_permsToBitmap() public {
        uint8[] memory perms = new uint8[](3);
        perms[0] = 1;
        perms[1] = 2;
        perms[2] = 3;
        uint256 bitmap = ac.permsToBitmap(perms);
        // bitmap == 1110
        assertEq(bitmap, 14);
    }
}
