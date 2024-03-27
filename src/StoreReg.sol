// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {RelayReg} from "./RelayReg.sol";
import {AccessControl} from "./AccessControl.sol";

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

    /// we could use enums here, but the are not exposed in the abi and change in order of functions would be brittle
    uint8 public constant PERM_addPermission = 0;
    uint8 public constant PERM_removePermission = 1;
    uint8 public constant PERM_updateRootHash = 2;
    uint8 public constant PERM_addRelay = 3;
    uint8 public constant PERM_removeRelay = 4;
    uint8 public constant PERM_replaceRelay = 5;
    uint8 public constant PERM_registerUser = 6;
    uint8 public constant PERM_removeUser = 7;
    uint8 public constant PERM_publishInviteVerifier = 8;

    constructor(RelayReg r) ERC721() {
        relayReg = r;
    }

    function name() public pure override returns (string memory) {
        return "StoreRegistry";
    }

    function symbol() public pure override returns (string memory) {
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
        if (!_checkIsConfiguredRelay(storeId) && !hasPermission(storeId, msg.sender, PERM_updateRootHash)) {
            revert NotAuthorized(PERM_updateRootHash);
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
        permissionGuard(storeId, PERM_addRelay);
        relays[storeId].push(relayId);
    }

    /// @notice replaceRelay replaces a relay in the store
    /// @param storeId The store nft
    /// @param idx The index of the relay to replace
    /// @param relayId The new relay nft
    function replaceRelay(uint256 storeId, uint8 idx, uint256 relayId) public {
        permissionGuard(storeId, PERM_replaceRelay);
        relays[storeId][idx] = relayId;
    }

    /// @notice removeRelay removes a relay from the store
    /// @param storeId The store nft
    /// @param idx The index of the relay to remove
    function removeRelay(uint256 storeId, uint8 idx) public {
        permissionGuard(storeId, uint8(PERM_removeRelay));
        uint256 last = relays[storeId].length - 1;
        if (last != idx) {
            relays[storeId][idx] = relays[storeId][last];
        }
        relays[storeId].pop();
    }

    /// @dev checks if the sender is part of the configured relays
    /// @param storeId The store nft
    function _checkIsConfiguredRelay(uint256 storeId) internal view returns (bool) {
        uint256[] storage allRelays = relays[storeId];
        for (uint256 index = 0; index < allRelays.length; index++) {
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
        permissionGuard(storeId, uint8(PERM_publishInviteVerifier));
        invites.set(calculateIdx(storeId, verifier));
    }

    /// @dev utility function to get the message hash for the invite verfication
    function _getTokenMessageHash(address user) public pure returns (bytes32) {
        string memory hexAdd = LibString.toHexString(uint256(uint160(user)), 20);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n52enrolling:", hexAdd));
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
        if (newIsSet) revert NoVerifier();
        // register the new user
        _addUser(storeId, user, (1 << PERM_updateRootHash));
    }

    /**
     *  USER CONTROL
     */

    /// @dev manually add user, identified by their wallet addr, to the store
    /// @param storeId The store nft
    /// @param user The address of the user
    /// @param perms The perimission to assign to the new users
    function registerUser(uint256 storeId, address user, uint256 perms) public {
        allPermissionsGuard(storeId, perms | 1 << PERM_registerUser);
        // save the user
        _addUser(storeId, user, perms);
    }

    /// @dev remove user. The address that is removing the user must have all or more permissions than the user being removed. Or be the owner of the store
    /// @param storeId The store
    /// @param user The address of the user
    function removeUser(uint256 storeId, address user) public {
        allPermissionsGuard(storeId, getAllPermissions(storeId, user) | 1 << PERM_removeUser);
        _removeUser(storeId, user);
    }

    // @dev adds a permision if the calling user has that permision and the permision to remove permisions
    function addPermission(uint256 storeId, address user, uint8 perm) public {
        allPermissionsGuard(storeId, 1 << perm | 1 << PERM_addPermission);
        _addPermission(storeId, user, perm);
    }

    // @dev removes a permision if the calling user has that permision and the permision to remove permisions
    function removePermission(uint256 storeId, address user, uint8 perm) public {
        allPermissionsGuard(storeId, 1 << perm | PERM_removePermission);
        _removePermission(storeId, user, perm);
    }

    /// @notice calculates a unique index given an ID and an address
    /// @dev the storeID must be hashed before being XORed to prevent collisions since an attacker can choose the storeID.
    function calculateIdx(uint256 id, address addr) internal pure returns (uint256) {
        return uint256(uint160(addr)) ^ uint256(keccak256(abi.encode(id)));
    }
}
