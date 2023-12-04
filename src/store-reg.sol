// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./relay-reg.sol";

enum AccessLevel { Zero, Clerk, Admin, Owner }

contract StoreReg is ERC721 {
    uint256 private _storeIds;
    // info per store
    mapping(uint256 => bytes32) public rootHashes;
    mapping(uint256 => uint256[]) public relays;
    mapping(uint256 => mapping(address => AccessLevel)) public storesToUsers;
    RelayReg public relayReg;

    constructor(RelayReg r) ERC721("Store", "MMSR") {
        relayReg = r;
    }

    // creates a new store
    function mint(address owner, bytes32 rootHash) public returns (uint256) {
        // safe mint checks id
        uint256 newId = _storeIds++;
        _mint(owner, newId);
        // update the hash
        rootHashes[newId] = rootHash;
        return newId;
    }

    function relayIsSender(uint256 storeId) internal view returns (bool) {
        uint256[] memory allRelays = relays[storeId];
        for (uint256 index = 0; index < allRelays.length; index++) {
            uint256 relayId = allRelays[index];
            address relayAddr = relayReg.ownerOf(relayId);
            if (relayAddr == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function updateRootHash(uint256 storeId, bytes32 hash) public {
        require(hasAtLeastAccess(storeId, msg.sender, AccessLevel.Clerk)
            || relayIsSender(storeId),
            "access denied");
        rootHashes[storeId] = hash;
    }

    function updateRelays(uint256 storeId, uint256[] memory _relays) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        relays[storeId] = _relays;
    }

    // access control

    function _checkIsOwner(uint256 storeId) view internal returns (bool) {
         address owner = _ownerOf(storeId);
         return _msgSender() == owner;
            isApprovedForAll(owner, msg.sender) ||
            _msgSender() == getApproved(storeId);
    }

    function requireIsOwner(uint256 storeId) view internal {
        require(_checkIsOwner(storeId),
            "NOT_AUTHORIZED"
        );
    }

    function requireOnlyAdminOrHigher(uint256 storeId, address who) public view {
        if (_checkIsOwner(storeId)) {
            return;
        }
        AccessLevel acl = storesToUsers[storeId][who];
        require(acl != AccessLevel.Zero && acl != AccessLevel.Clerk, "no such user");
    }

    function registerUser(uint256 storeId, address addr, AccessLevel acl) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        require(addr != address(0), "can't be zero address");
        require(acl == AccessLevel.Clerk || acl == AccessLevel.Admin, "invalid access level");
        // that is the user we want to save on chain
        storesToUsers[storeId][addr] = acl;
    }

    function removeUser(uint256 storeId, address who) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        AccessLevel theirAcl = storesToUsers[storeId][who];
        if (theirAcl == AccessLevel.Zero) {
            // already removed
            return;
        }
        // can't delete things in a mapping so we overwrite with an empty entry
        storesToUsers[storeId][who] = AccessLevel.Zero;
    }

    function hasAtLeastAccess(uint256 storeId, address addr, AccessLevel want) public view returns (bool) {
        AccessLevel has = storesToUsers[storeId][addr];
        address owner = _ownerOf(storeId);
        if (want == AccessLevel.Clerk) {
            return has != AccessLevel.Zero || owner == addr;
        } else if (want == AccessLevel.Admin) {
            return has == AccessLevel.Admin || owner == addr;
        } else if (want == AccessLevel.Owner) {
            return addr == owner;
        }
        require(false, "unhandled access level");
        return false; // unreachable but need to return something
    }
}
