// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {RelayReg} from "./RelayReg.sol";
import {AccessControl} from "./AccessControl.sol";

contract ShopReg is AccessControl {
    using LibBitmap for LibBitmap.Bitmap;

    RelayReg public relayReg;

    error NoVerifier();
    error InvalidNonce(uint64 cur, uint64 _nonce);

    /// @notice rootHashes is a mapping of shops to their state root hash
    mapping(uint256 shopid => bytes32) public rootHashes;
    /// @notice sequenceNonce is a mapping of shops to the nonce of the last event used in the root hash
    mapping(uint256 shopid => uint64) public nonce;
    /// @notice relays is a mapping of shop nfts to their relays
    mapping(uint256 shopid => uint256[]) public relays;

    mapping(uint256 => string) public shopURIs;

    /// @notice invites is a mapping of shop nfts to their one-time use registration invites
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
        return "ShopRegistry";
    }

    function symbol() public pure override returns (string memory) {
        return "SR";
    }

    /// @notice Returns the metadata URI for a given shop
    /// @param id The shop nft
    /// @return url to the metadata
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return shopURIs[id];
    }

    /// @notice Sets the metadata URI for a given shop with the provided URI
    /// @param shopId shop token id, newTokenURI uri to metadata
    function setTokenURI(uint256 shopId, string memory newTokenURI) public {
        require(ownerOf(shopId) == msg.sender, "NOT_AUTHORIZED");
        shopURIs[shopId] = newTokenURI;
    }

    /// @notice mint registeres a new shop and creates a NFT for it
    /// @param shopId The shop nft. Needs to be unique or it will revert
    /// @param owner The owner of the shop
    function mint(uint256 shopId, address owner) public {
        // safe mint checks if id is taken
        _safeMint(owner, shopId);
    }

    /// @notice updateRootHash updates the state root of the shop
    /// @param shopId The shop nft
    /// @param hash The new state root hash
    function updateRootHash(uint256 shopId, bytes32 hash, uint64 _nonce) public {
        if (!_checkIsConfiguredRelay(shopId) && !hasPermission(shopId, msg.sender, PERM_updateRootHash)) {
            revert NotAuthorized(PERM_updateRootHash);
        }
        rootHashes[shopId] = hash;
        uint64 curNonce = nonce[shopId];
        if (curNonce >= _nonce) {
            revert InvalidNonce(curNonce, _nonce);
        }
        nonce[shopId] = _nonce;
    }

    /**
     *  RELAY CONFIGURATION
     */

    /// @notice getRelayCount returns the number of relays for a shop
    /// @param shopId The shop nft
    /// @return The number of relays
    function getRelayCount(uint256 shopId) public view returns (uint256) {
        return relays[shopId].length;
    }

    /// @notice getAllRelays returns all relays for a shop
    /// @param shopId The shop nft
    /// @return An array of relay nfts
    function getAllRelays(uint256 shopId) public view returns (uint256[] memory) {
        return relays[shopId];
    }

    /// @notice addRelay adds a relay to the shop
    /// @param shopId The shop nft
    /// @param relayId The relay nft
    function addRelay(uint256 shopId, uint256 relayId) public {
        permissionGuard(shopId, PERM_addRelay);
        relays[shopId].push(relayId);
    }

    /// @notice replaceRelay replaces a relay in the shop
    /// @param shopId The shop nft
    /// @param idx The index of the relay to replace
    /// @param relayId The new relay nft
    function replaceRelay(uint256 shopId, uint8 idx, uint256 relayId) public {
        permissionGuard(shopId, PERM_replaceRelay);
        relays[shopId][idx] = relayId;
    }

    /// @notice removeRelay removes a relay from the shop
    /// @param shopId The shop nft
    /// @param idx The index of the relay to remove
    function removeRelay(uint256 shopId, uint8 idx) public {
        permissionGuard(shopId, uint8(PERM_removeRelay));
        uint256 last = relays[shopId].length - 1;
        if (last != idx) {
            relays[shopId][idx] = relays[shopId][last];
        }
        relays[shopId].pop();
    }

    /// @dev checks if the sender is part of the configured relays
    /// @param shopId The shop nft
    function _checkIsConfiguredRelay(uint256 shopId) internal view returns (bool) {
        uint256[] storage allRelays = relays[shopId];
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

    /// @notice adds a new one-time use registration invite to the shop
    /// @param shopId The shop nft
    /// @param verifier The address of the invite verifier (public key)
    function publishInviteVerifier(uint256 shopId, address verifier) public {
        permissionGuard(shopId, uint8(PERM_publishInviteVerifier));
        invites.set(calculateIdx(shopId, verifier));
    }

    /// @dev utility function to get the message hash for the invite verfication
    function _getTokenMessageHash(address user) public pure returns (bytes32) {
        string memory hexAdd = LibString.toHexString(uint256(uint160(user)), 20);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n52enrolling:", hexAdd));
    }

    /// @notice redeem one of the invites. (v,r,s) are the signature
    /// @param shopId The shop nft
    /// @param v The recovery id
    /// @param r The r value of the signature
    /// @param s The s value of the signature
    /// @param user The address of the user to register. Will become a Clerk.
    function redeemInvite(uint256 shopId, uint8 v, bytes32 r, bytes32 s, address user) public {
        // check signature
        address recovered = ecrecover(_getTokenMessageHash(user), v, r, s);
        bool newIsSet = invites.toggle(calculateIdx(shopId, recovered));
        if (newIsSet) revert NoVerifier();
        // register the new user
        _addUser(shopId, user, (1 << PERM_updateRootHash));
    }

    /**
     *  USER CONTROL
     */

    /// @dev manually add user, identified by their wallet addr, to the shop
    /// @param shopId The shop nft
    /// @param user The address of the user
    /// @param perms The perimission to assign to the new users
    function registerUser(uint256 shopId, address user, uint256 perms) public {
        allPermissionsGuard(shopId, perms | 1 << PERM_registerUser);
        // save the user
        _addUser(shopId, user, perms);
    }

    /// @dev remove user. The address that is removing the user must have all or more permissions than the user being removed. Or be the owner of the shop
    /// @param shopId The shop
    /// @param user The address of the user
    function removeUser(uint256 shopId, address user) public {
        allPermissionsGuard(shopId, getAllPermissions(shopId, user) | 1 << PERM_removeUser);
        _removeUser(shopId, user);
    }

    // @dev adds a permision if the calling user has that permision and the permision to remove permisions
    function addPermission(uint256 shopId, address user, uint8 perm) public {
        allPermissionsGuard(shopId, 1 << perm | 1 << PERM_addPermission);
        _addPermission(shopId, user, perm);
    }

    // @dev removes a permision if the calling user has that permision and the permision to remove permisions
    function removePermission(uint256 shopId, address user, uint8 perm) public {
        allPermissionsGuard(shopId, 1 << perm | PERM_removePermission);
        _removePermission(shopId, user, perm);
    }

    /// @notice calculates a unique index given an ID and an address
    /// @dev the shopID must be hashed before being XORed to prevent collisions since an attacker can choose the shopID.
    function calculateIdx(uint256 id, address addr) internal pure returns (uint256) {
        return uint256(uint160(addr)) ^ uint256(keccak256(abi.encode(id)));
    }
}
