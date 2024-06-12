// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";

abstract contract AccessControl is ERC721 {
    mapping(uint256 id => mapping(address user => uint256)) permissionsStore;

    error NotAuthorized(uint8 permision);

    event UserAdded(uint256 indexed shopId, address user, uint256 permissions);
    event UserRemoved(uint256 indexed shopId, address users);
    event PermissionAdded(uint256 indexed shopId, address user, uint8 permission);
    event PermissionRemoved(uint256 indexed shopId, address user, uint8 permission);

    function _addUser(uint256 id, address user, uint256 perms) internal {
        emit UserAdded(id, user, perms);
        permissionsStore[id][user] = perms;
    }

    function _removeUser(uint256 id, address user) internal {
        emit UserRemoved(id, user);
        delete permissionsStore[id][user];
    }

    /// @notice checks if the caller has the permission and throws if it does not
    /// @param id the id of the ERC721
    /// @param perm the permission to check
    function permissionGuard(uint256 id, uint8 perm) public view {
        if (!hasPermission(id, msg.sender, perm)) revert NotAuthorized(perm);
    }

    /// @notice checks if the caller has all the permissions and throws if it does not
    /// @param id the id of the ERC721
    /// @param perms the permissions to check as a bitmap of permissions
    function allPermissionsGuard(uint256 id, uint256 perms) public view {
        // we don't know which permision was missing so we use 0xff to signal that
        if (!hasEnoughPermissions(id, msg.sender, perms)) revert NotAuthorized(0xff);
    }

    /// @notice gives a permission to a user
    /// @param id the id of the ERC721
    /// @param user the address of the user
    /// @param perm the permission to give
    function _addPermission(uint256 id, address user, uint8 perm) internal {
        emit PermissionAdded(id, user, perm);
        permissionsStore[id][user] |= (1 << perm);
    }

    /// @notice removes a permission from a user
    function _removePermission(uint256 id, address user, uint8 perm) internal {
        emit PermissionRemoved(id, user, perm);
        permissionsStore[id][user] &= ~(1 << perm);
    }

    /// @notice returns a user's perimsion bitmap
    function getAllPermissions(uint256 id, address user) public view returns (uint256) {
        return permissionsStore[id][user];
    }

    /// @notice checks if a user has a permission
    function hasPermission(uint256 id, address user, uint8 perm) public view returns (bool) {
        return permissionsStore[id][user] & (1 << perm) != 0 || ownerOf(id) == user;
    }

    /// @notice checks if a user has the same or more permissions as perms. Where perms is a bitmap of permissions (1 << perm2 | 1 << perm2 ...)
    /// @param id the id of the ERC721
    /// @param user the address of the user
    /// @param perms the permissions to check
    function hasEnoughPermissions(uint256 id, address user, uint256 perms) public view returns (bool) {
        uint256 userPerms = permissionsStore[id][user];
        // converse nonimplication implemeted as XOR(OR(Q, P), P)
        return ((userPerms | perms) ^ userPerms) == 0 || ownerOf(id) == user;
    }

    /// @notice converts an array of permissions to a bitmap
    /// @param perms the permissions to convert
    function permsToBitmap(uint8[] memory perms) public pure returns (uint256) {
        uint256 bitmap;
        for (uint8 i = 0; i < perms.length; i++) {
            bitmap |= 1 << perms[i];
        }
        return bitmap;
    }
}
