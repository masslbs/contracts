// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// used as salt for creating an OrderPayment Contract
contract ShopReg is  ERC721Enumerable, ERC721URIStorage {
    error InvalidNonce(uint64 cur, uint64 _nonce);

    /// @notice rootHashes is a mapping of shops to their state root hash
    mapping(uint256 shopid => bytes32) public rootHashes;
    /// @notice sequenceNonce is a mapping of shops to the nonce of the last event used in the root hash
    mapping(uint256 shopid => uint64) public nonce;
    /// @notice relays is a mapping of shop nfts to their relays
    mapping(uint256 shopid => uint256[]) public relays;
    mapping(uint256 shopid => bytes32) public schema;

    constructor() ERC721("ShopRegistry", "SR") {
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Sets the metadata URI for a given shop with the provided URI
    /// @param shopId shop token id, newTokenURI uri to metadata
    function setTokenURI(uint256 shopId, string memory newTokenURI) public {
        require(ownerOf(shopId) == msg.sender, "NOT_AUTHORIZED");
        _setTokenURI(shopId, newTokenURI);
    }

    /// @notice mint registers a new shop and creates a NFT for it
    /// @param shopId The shop nft. Needs to be unique or it will revert
    /// @param _schema The schema of the shop
    /// @param owner The owner of the shop
    function mint(uint256 shopId, bytes32 _schema, address owner) public {
        // safe mint checks if id is taken
        _safeMint(owner, shopId);
        schema[shopId] = _schema;
    }

    /// @notice updateRootHash updates the state root of the shop
    /// @param shopId The shop nft
    /// @param hash The new state root hash
    function updateRootHash(
        uint256 shopId,
        bytes32 hash,
        uint64 _nonce
    ) public {
        require(ownerOf(shopId) == msg.sender || _checkIsConfiguredRelay(shopId), "NOT_AUTHORIZED");
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
    function getAllRelays(
        uint256 shopId
    ) public view returns (uint256[] memory) {
        return relays[shopId];
    }

    /// @notice addRelay adds a relay to the shop
    /// @param shopId The shop nft
    /// @param relayId The relay nft
    function addRelay(uint256 shopId, uint256 relayId) public {
        require(ownerOf(shopId) == msg.sender, "NOT_AUTHORIZED");
        relays[shopId].push(relayId);
    }

    /// @notice replaceRelay replaces a relay in the shop
    /// @param shopId The shop nft
    /// @param idx The index of the relay to replace
    /// @param relayId The new relay nft
    function replaceRelay(uint256 shopId, uint8 idx, uint256 relayId) public {
        require(ownerOf(shopId) == msg.sender, "NOT_AUTHORIZED");
        relays[shopId][idx] = relayId;
    }

    /// @notice removeRelay removes a relay from the shop
    /// @param shopId The shop nft
    /// @param idx The index of the relay to remove
    function removeRelay(uint256 shopId, uint8 idx) public {
        require(ownerOf(shopId) == msg.sender, "NOT_AUTHORIZED");
        uint256 last = relays[shopId].length - 1;
        if (last != idx) {
            relays[shopId][idx] = relays[shopId][last];
        }
        relays[shopId].pop();
    }

    /// @dev checks if the sender is part of the configured relays
    /// @param shopId The shop nft
    function _checkIsConfiguredRelay(
        uint256 shopId
    ) internal view returns (bool) {
        uint256[] storage allRelays = relays[shopId];
        for (uint256 index = 0; index < allRelays.length; index++) {
            uint256 relayId = allRelays[index];
            address relayAddr = this.ownerOf(relayId);
            if (relayAddr == msg.sender) {
                return true;
            }
        }
        return false;
    }
}
