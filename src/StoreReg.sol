// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { ERC721 } from "solady/src/tokens/ERC721.sol";
import { LibBitmap } from "solady/src/utils/LibBitmap.sol";
import { LibString } from "solady/src/utils/LibString.sol";
import { RelayReg } from "./RelayReg.sol";
import { AccessControl } from "./AccessControl.sol";

/// @notice AccessLevel is a enum that represents the different access levels of a user
/// @notice Zero no access
/// @notice Clerk can read and write
/// @notice Admin can read, write, and add other users
/// @notice Owner only usable for hasAtLeastAccess checking

contract StoreReg is AccessControl {
    using LibBitmap for LibBitmap.Bitmap;
    RelayReg public relayReg;

    error NoVerifier();

    /// @notice rootHashes is a mapping of store nfts to their state root hash
    mapping(uint256 storeid => bytes32) public rootHashes;

    /// @notice relays is a mapping of store nfts to their relays
    mapping(uint256 storeid => uint256[]) public relays;

    /// @notice invites is a mapping of store nfts to their one-time use registration invites
    LibBitmap.Bitmap private invites;

    /// @notice Permissions the different permissions corrisponding to a function in the contract
    enum Permissions {
        setPermissionBatch,
        addPermission,
        removePermission,
        updateRootHash,
        addRelay,
        removeRelay,
        replaceRelay,
        registerUser,
        removeUser,
        publishInviteVerifier
    }

    // Roles are bitmasks of the permissions
    uint256 constant public CLERK =  (1 << uint8(Permissions.updateRootHash)); 
    uint256 constant public RELAY_ADMIN =
        (1 << uint8(Permissions.addRelay)) | 
        (1 << uint8(Permissions.removeRelay)) |
        (1 << uint8(Permissions.replaceRelay)); 
    uint256 constant public ADMIN =  RELAY_ADMIN | CLERK |
        (1 << uint8(Permissions.registerUser)) |
        (1 << uint8(Permissions.removeUser)) |
        (1 << uint8(Permissions.publishInviteVerifier));

    constructor(RelayReg r) ERC721() {
        relayReg = r;
    }

    function name() public pure override returns (string memory)
    {
        return "StoreRegistry";
    }

    function symbol() public pure override returns (string memory)
    {
        return "SR";
    }


    /// @notice Returns the metadata URI for a given store
    /// @param id The store nft
    /// @return url to the metadata
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return relayReg.relayURIs(relays[id][0]);
    }

    /// @notice mint registeres a new store and creates a NFT for it
    /// @param storeId The store nft. Needs to be unique or it will revert
    /// @param owner The owner of the store
    function mint(uint256 storeId, address owner) public {
        // safe mint checks if id is taken
        _safeMint(owner, storeId);
    }

    /// @notice updateRootHash updates the state root of the store
    /// @param storeId The store nft
    /// @param hash The new state root hash
    function updateRootHash(uint256 storeId, bytes32 hash) public {
        if(!_checkIsConfiguredRelay(storeId) 
            && !hasPermission(storeId, msg.sender, uint8(Permissions.updateRootHash))
            && ownerOf(storeId) != msg.sender
          ) {
                revert NotAuthorized(uint8(Permissions.updateRootHash));
            }
       rootHashes[storeId] = hash;
    }

    /**
     *  RELAY CONFIGURATION
     */

    /// @notice getRelayCount returns the number of relays for a store
    /// @param storeId The store nft
    /// @return The number of relays
    function getRelayCount(uint256 storeId) public view returns (uint256) {
        return relays[storeId].length;
    }

    /// @notice getAllRelays returns all relays for a store
    /// @param storeId The store nft
    /// @return An array of relay nfts
    function getAllRelays(uint256 storeId) public view returns (uint256[] memory) {
        return relays[storeId];
    }

    /// @notice addRelay adds a relay to the store
    /// @param storeId The store nft
    /// @param relayId The relay nft
    function addRelay(uint256 storeId, uint256 relayId) public {
        checkPermission(storeId, uint8(Permissions.addRelay));
        relays[storeId].push(relayId);
    }

    /// @notice replaceRelay replaces a relay in the store
    /// @param storeId The store nft
    /// @param idx The index of the relay to replace
    /// @param relayId The new relay nft
    function replaceRelay(uint256 storeId,  uint8 idx, uint256 relayId) public {
        checkPermission(storeId, uint8(Permissions.replaceRelay));
        relays[storeId][idx] = relayId;
    }

    /// @notice removeRelay removes a relay from the store
    /// @param storeId The store nft
    /// @param idx The index of the relay to remove
    function removeRelay(uint256 storeId, uint8 idx) public {
        checkPermission(storeId, uint8(Permissions.removeRelay));
        uint last = relays[storeId].length - 1;
        if(last != idx) {
            relays[storeId][idx] = relays[storeId][last];
        }
        relays[storeId].pop();
    }

    /// @dev checks if the sender is part of the configured relays
    /// @param storeId The store nft
    function _checkIsConfiguredRelay(uint256 storeId) internal view returns (bool) {
        uint[] storage allRelays = relays[storeId];
        for (uint index = 0; index < allRelays.length; index++) {
            uint256 relayId = allRelays[index];
            address relayAddr = relayReg.ownerOf(relayId);
            if (relayAddr == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /**
     *  INVITES
     */

    /// @notice adds a new one-time use registration invite to the store
    /// @param storeId The store nft
    /// @param verifier The address of the invite verifier (public key)
    function publishInviteVerifier(uint256 storeId, address verifier) public {
        checkPermission(storeId, uint8(Permissions.publishInviteVerifier));
        invites.set(calculateIdx(storeId, verifier));
    }

    /// @dev utility function to get the message hash for the invite verfication
    function _getTokenMessageHash(address user) public pure returns (bytes32) {
        string memory hexAdd = LibString.toHexString(uint256(uint160(user)), 20);
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n52enrolling:", hexAdd));
    }

    /// @notice redeem one of the invites. (v,r,s) are the signature
    /// @param storeId The store nft
    /// @param v The recovery id
    /// @param r The r value of the signature
    /// @param s The s value of the signature
    /// @param user The address of the user to register. Will become a Clerk.
    function redeemInvite(uint256 storeId, uint8 v, bytes32 r, bytes32 s, address user) public {
        // check signature
        address recovered = ecrecover(_getTokenMessageHash(user), v, r, s);
        bool newIsSet = invites.toggle(calculateIdx(storeId, recovered));
        if(newIsSet) revert NoVerifier();
        // register the new user
        _addUser(storeId, user, CLERK);
    }

    /**
     *  USER CONTROL
     */

    /// @dev manually add user, identified by their wallet addr, to the store
    /// @param storeId The store nft
    /// @param user The address of the user
    /// @param perms The perimission to assign to the new users
    function registerUser(uint256 storeId, address user, uint256 perms) public {
        checkAllPermissions(storeId, perms | 1 << uint8(Permissions.registerUser));
        // save the user
        _addUser(storeId, user, perms);
    }

    /// @dev remove user. The address that is removing the user must have all or more permissions than the user being removed. Or be the owner of the store
    /// @param storeId The store
    /// @param user The address of the user
    function removeUser(uint256 storeId, address user) public {
        checkAllPermissions(storeId, getAllPermissions(storeId, user) | 1 << uint8(Permissions.removeUser));
        _removeUser(storeId, user);
    }
}
