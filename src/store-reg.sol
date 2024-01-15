// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./relay-reg.sol";

enum AccessLevel { Zero, Clerk, Admin, Owner } // note: currently owner is not really used

contract StoreReg is ERC721 {
    RelayReg public relayReg;

    // info per store
    mapping(uint256 => bytes32) public rootHashes;
    mapping(uint256 => uint256[]) internal relays;
    mapping(uint256 => mapping(address => AccessLevel)) public storesToUsers;
    mapping(uint256 => mapping(address => bool)) public storesToRegistrationTokens;

    constructor(RelayReg r) ERC721("Store", "MMSR") {
        relayReg = r;
    }

    function registerStore(uint256 storeId, address owner, bytes32 rootHash) public {
        // safe mint checks if id is taken
        _safeMint(owner, storeId);
        // update the hash
        rootHashes[storeId] = rootHash;
    }

    function updateRootHash(uint256 storeId, bytes32 hash) public {
        require(hasAtLeastAccess(storeId, msg.sender, AccessLevel.Clerk)
            || _checkIsConfiguredRelay(storeId),
            "access denied");
        rootHashes[storeId] = hash;
    }

    // relay config things

    function getRelayCount(uint256 storeId) public view returns (uint256) {
        return relays[storeId].length;
    }

    function getAllRelays(uint256 storeId) public view returns (uint256[] memory) {
        require(getRelayCount(storeId) > 0, "no relays configured");
        return relays[storeId];
    }

    function updateRelays(uint256 storeId, uint256[] memory _relays) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        relays[storeId] = _relays;
    }

    // access control

    function _checkIsConfiguredRelay(uint256 storeId) internal view returns (bool) {
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

    function _checkIsOwner(uint256 storeId) view internal returns (bool) {
         address owner = _ownerOf(storeId);
         return _msgSender() == owner ||
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

    function getTokenMessageHash(address user) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n52enrolling:", Strings.toHexString(user)));
    }

    // adds a new one-time use registration token to the store
    function registrationTokenPublish(uint256 storeId, address token) public {
        requireOnlyAdminOrHigher(storeId, msg.sender);
        storesToRegistrationTokens[storeId][token] = true;
    }

    // redeem one of the registration tokens. (v,r,s) are the signature
    function regstrationTokenRedeem(uint256 storeId, uint8 v, bytes32 r, bytes32 s, address user) public {
        // see if user is already registered
        bool hasAlready = hasAtLeastAccess(storeId, user, AccessLevel.Clerk);
        require(!hasAlready, "already registered");
        // check signature
        address recovered = ecrecover(getTokenMessageHash(user), v, r, s);
        bool isAllowed = storesToRegistrationTokens[storeId][recovered];
        require(isAllowed, "no such token");
        delete storesToRegistrationTokens[storeId][recovered];
        // register the new user
        storesToUsers[storeId][user] = AccessLevel.Clerk;
    }


    // manually add user, identified by their wallet addr, to the store
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
        delete storesToUsers[storeId][who];
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
