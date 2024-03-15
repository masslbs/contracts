// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {AccessControl} from "../src/AccessControl.sol";


contract MockAccessControlNFT is AccessControl {
    uint8 internal permissionForTestFunction = 66;

    constructor() {
    }

    function mint(uint256 _id, address _addr) public {
        _mint(_addr, _id );
    }

    function name() public  pure override returns (string memory) {
        return "RelayRegestry";
    }

    function symbol() public  pure override returns (string memory) {
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
    uint256 internal constant store_id = 1;
    address internal user = address(0xff);

    event UserAdded(uint256 indexed storeId, address user, uint256 permissions);
    event UserRemoved(uint256 indexed storeId, address users);
    event PermissionAdded(uint256 indexed storeId, address user, uint8 permission);
    event PermissionRemoved(uint256 indexed storeId, address user, uint8 permission);

    function setUp() public {
        ac = new MockAccessControlNFT();
        ac.mint(store_id, address(this));
    }

    function test_ownerShouldAlwayHavePermission() public {
        assertTrue(ac.hasEnoughPermissions(store_id, address(this), 0));
        assertTrue(ac.hasPermission(store_id, address(this), 1));
        assertTrue(ac.hasPermission(store_id, address(this), 0xff));
    }

    function test_ownerShouldAlwayHaveEnufPermissions() public {
        assertTrue(ac.hasEnoughPermissions(store_id, address(this), 0));
        assertTrue(ac.hasEnoughPermissions(store_id, address(this), 1));
        assertTrue(ac.hasEnoughPermissions(store_id, address(this), ALL_PERMS));
    }

    function test_shouldNotHavePerm () public {
        for (uint8 i = 0; i < 0xff; i++) {
            assertFalse(ac.hasPermission(store_id, user, i));
        }
    }

    function test_shouldNotHaveEnufPerms() public {
        assertTrue(ac.hasEnoughPermissions(store_id, user, 0));
        assertFalse(ac.hasEnoughPermissions(store_id, user, 1));
        assertFalse(ac.hasEnoughPermissions(store_id, user, ALL_PERMS));
    }

    function test_newUserShouldEmit() public {
        vm.expectEmit();
        emit UserAdded(store_id, user, ALL_PERMS);
        ac.addUser(store_id, user, ALL_PERMS);
    }

    function test_removedUserShouldEmit() public {
        ac.addUser(store_id, user, ALL_PERMS);
        vm.expectEmit();
        emit UserRemoved(store_id, user);
        ac.removeUser(store_id, user, ALL_PERMS);
    }

    function test_shouldHavePerms() public {
        ac.addUser(store_id, user, ALL_PERMS);
        for (uint8 i = 0; i < 0xff; i++) {
            assertTrue(ac.hasPermission(store_id, user, i));
        }
    }

    function test_shouldHaveEnufPerms() public {
        ac.addUser(store_id, user, ALL_PERMS);
        assertTrue(ac.hasEnoughPermissions(store_id, user, 0));
        assertTrue(ac.hasEnoughPermissions(store_id, user, 1));
        assertTrue(ac.hasEnoughPermissions(store_id, user, ALL_PERMS));
    }

    function test_addingPermisionShouldEmit() public {
        uint8 perm = 1;
        vm.expectEmit();
        emit PermissionAdded(store_id, user, perm);
        ac.addPermission(store_id, user, perm);
    }


    function test_addedPermissionSHouldExist() public {
        uint8 perm = 1;
        ac.addPermission(store_id, user, perm);
        assertTrue(ac.hasPermission(store_id, user, perm));
    }

    function test_removePermissionShouldEmit() public {
        uint8 perm = 1;
        ac.addPermission(store_id, user, perm);
        vm.expectEmit();
        emit PermissionRemoved(store_id, user, perm);
        ac.removePermission(store_id, user, perm);
    }

    function test_removedPermissionShouldNotExist() public {
        uint8 perm = 1;
        ac.addPermission(store_id, user, perm);
        ac.removePermission(store_id, user, perm);
        assertFalse(ac.hasPermission(store_id, user, perm));
    }
}
