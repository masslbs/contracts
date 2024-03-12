// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { ERC721 } from "solady/src/tokens/ERC721.sol";
import { LibBitmap } from "solady/src/utils/LibBitmap.sol";
import { LibString } from "solady/src/utils/LibString.sol";
import "./relay-reg.sol";

/// @notice AccessLevel is a enum that represents the different access levels of a user
/// @notice Zero no access
/// @notice Clerk can read and write
/// @notice Admin can read, write, and add other users
/// @notice Owner only usable for hasAtLeastAccess checking
enum AccessLevel { Zero, Clerk, Admin, Owner } 

contract StoreReg is ERC721 {
    using LibBitmap for LibBitmap.Bitmap;
    RelayReg public relayReg;

    event UserAdded(uint256 indexed storeId, address user);
    event UserRemoved(uint256 indexed storeId, address users);
    error NoVerifier();
    error NotAuthorized();
    error InvalidAccessLevel();

    /// @notice rootHashes is a mapping of store nfts to their state root hash
    mapping(uint256 storeid => bytes32) public rootHashes;

    /// @notice relays is a mapping of store nfts to their relays
    mapping(uint256 storeid => uint256[]) public relays;

    /// @notice storesToUsers is a mapping of store nfts to their users and their access levels
    mapping(uint256 storeid => mapping(address storeuser => AccessLevel)) public storesToUsers;

    /// @notice invites is a mapping of store nfts to their one-time use registration invites
    LibBitmap.Bitmap private invites;

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
        if(!(_checkIsConfiguredRelay(storeId) 
            || hasAtLeastAccess(storeId, msg.sender, AccessLevel.Clerk))) revert NotAuthorized();
       rootHashes[storeId] = hash;
    }

    // relay config things
    // ===================

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
        requireOnlyAdminOrHigher(storeId, msg.sender);
        relays[storeId].push(relayId);
    }

    /// @notice replaceRelay replaces a relay in the store
    /// @param storeId The store nft
    /// @param idx The index of the relay to replace
    /// @param relayId The new relay nft
    function replaceRelay(uint256 storeId,  uint8 idx, uint256 relayId) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        relays[storeId][idx] = relayId;
    }

    /// @notice removeRelay removes a relay from the store
    /// @param storeId The store nft
    /// @param idx The index of the relay to remove
    function removeRelay(uint256 storeId, uint8 idx) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        uint last = relays[storeId].length - 1;
        if(last != idx) {
            relays[storeId][idx] = relays[storeId][last];
        }
        relays[storeId].pop();
    }

    // access control
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

    /// @dev checks if the sender is the owner of the store
    function _checkIsOwner(uint256 storeId) view internal returns (bool) {
         address owner = ownerOf(storeId);
         return msg.sender == owner;
    }

    function requireIsOwner(uint256 storeId) view internal {
        if(!_checkIsOwner(storeId)) revert NotAuthorized();
    }

    function requireOnlyAdminOrHigher(uint256 storeId, address who) public view {
        if (_checkIsOwner(storeId)) {
            return;
        }
        AccessLevel acl = storesToUsers[storeId][who];
        if(acl == AccessLevel.Zero || acl == AccessLevel.Clerk) revert NotAuthorized();
    }

    /// @notice adds a new one-time use registration invite to the store
    /// @param storeId The store nft
    /// @param verifier The address of the invite verifier (public key)
    function publishInviteVerifier(uint256 storeId, address verifier) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        invites.set(_calulateInviteId(verifier, storeId));
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
        bool newIsSet = invites.toggle(_calulateInviteId(recovered, storeId));
        if(newIsSet) revert NoVerifier();
        // register the new user
        _addUser(storeId, user, AccessLevel.Clerk);
    }

    /// @dev manually add user, identified by their wallet addr, to the store
    /// @param storeId The store nft
    /// @param addr The address of the user
    /// @param acl The access level of the user. can only be clerk or admin.
    function registerUser(uint256 storeId, address addr, AccessLevel acl) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        // save the user
        _addUser(storeId, addr, acl);
    }

    /// @dev manually remove user, identified by their wallet addr, from the store
    function removeUser(uint256 storeId, address who) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        AccessLevel theirAcl = storesToUsers[storeId][who];
        if (theirAcl == AccessLevel.Zero) {
            // already removed
            return;
        }
        delete storesToUsers[storeId][who];
    }

    /// @notice checks if a user has at least a certain access level
    /// @param storeId The store nft
    /// @param addr The address of the user
    /// @param want The access level to check for
    /// @return true if the user has at least the access level
    function hasAtLeastAccess(uint256 storeId, address addr, AccessLevel want) public view returns (bool) {
        AccessLevel has = storesToUsers[storeId][addr];
        address owner = ownerOf(storeId);
        if (want == AccessLevel.Clerk) {
            return has != AccessLevel.Zero || owner == addr;
        } else if (want == AccessLevel.Admin) {
            return has == AccessLevel.Admin || owner == addr;
        } else if (want == AccessLevel.Owner) {
            return addr == owner;
        }
        revert InvalidAccessLevel();
    }

    function _addUser(uint256 storeId, address addr,  AccessLevel acl) internal {
        storesToUsers[storeId][addr] = acl;
        emit UserAdded(storeId, addr);
    }

    /// @notice calculates the invite id
    /// @dev the storeID must be hashed before being XORed to prevent collisions since an attacker can choose the storeID. 
    function _calulateInviteId(address verifier, uint256 storeId) internal pure returns (uint256) {
        return uint256(uint160(verifier)) ^ uint256(keccak256(abi.encode(storeId)));
    }

}
