// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { ERC721 } from "solady/src/tokens/ERC721.sol";

abstract contract AccessControl is ERC721 {
    mapping(uint256 id => mapping (address user => uint256)) permissionsStore;

    enum _Permissions {setPermissionBatch, addPermission, removePermission}

    error NotAuthorized(uint8 permision);

    event UserAdded(uint256 indexed storeId, address user, uint256 permissions);
    event UserRemoved(uint256 indexed storeId, address users);
    event PermissionAdded(uint256 indexed storeId, address user, uint8 permission);
    event PermissionRemoved(uint256 indexed storeId, address user, uint8 permission);
 
    /// @notice checks if the caller has the permission and throws if it does not
    /// @param id the id of the ERC721
    /// @param perm the permission to check
    function checkPermission(uint256 id, uint8 perm) public view {
        if(!hasPermission(id, msg.sender, perm) && ownerOf(id) != msg.sender) {
            revert NotAuthorized(perm);
        }
    }

    /// @notice checks if the caller has all the permissions and throws if it does not
    /// @param id the id of the ERC721
    /// @param perms the permissions to check
    function checkAllPermissions(uint256 id, uint256 perms) public view {
        if(!hasEnoughPermissions(id, msg.sender, perms) && ownerOf(id) != msg.sender) {
            // we don't know which permision was missing so we use 0xff to signal that
            revert NotAuthorized(0xff);
        }
    }

    /// @notice gives a permission to a user
    /// @param id the id of the ERC721
    /// @param user the address of the user
    /// @param perm the permission to give
    function addPermission(uint256 id, address user, uint8 perm) public {
        checkPermission(id, uint8(_Permissions.addPermission));
        emit PermissionAdded(id, user, perm);
        permissionsStore[id][user] |= (1 << perm); 
    }

    /// @notice removes a permission from a user
    function removePermission(uint256 id, address user, uint8 perm) public {
        checkPermission(id, uint8(_Permissions.removePermission));
        emit PermissionRemoved(id, user, perm);
        permissionsStore[id][user] &= ~(1 << perm); 
    }

    function _removeUser(uint256 id, address user) internal {
        emit UserRemoved(id, user);
        delete permissionsStore[id][user];
    }

    /// @notice returns a user's perimsion bitmap
    function getAllPermissions(uint256 id, address user) public view returns (uint256) {
        return permissionsStore[id][user];
    }

    /// @notice checks if a user has a permission
    function hasPermission(uint256 id, address user, uint8 perm) public view returns (bool) {
        return permissionsStore[id][user] & (1 << perm) != 0;
    }

    /// @notice checks if a user has all the permissions
    function hasEnoughPermissions(uint256 id, address user, uint256 perms) public view returns (bool) {
        return permissionsStore[id][user] >= perms;
    }

    function _addUser(uint256 id, address user, uint256 perms) internal {
        emit UserAdded(id, user, perms);
        permissionsStore[id][user] = perms;
    }
}
