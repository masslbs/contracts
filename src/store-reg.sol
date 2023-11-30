// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";


contract Store is ERC721 {
    uint256 private _storeIds;
    mapping(uint256 => bytes32) public storeRootHash;
    mapping(uint256 => string[]) public relays;

    constructor() ERC721("Store", "MMSR") {} 

    function authorized(uint256 id) view internal {
        address owner = _ownerOf(id);
        require(
            _msgSender() == owner ||
            isApprovedForAll(owner, msg.sender) ||
            _msgSender() == getApproved(id),
            "NOT_AUTHORIZED"
        );
    }

    function mintTo(address owner, bytes32 rootHash) public returns (uint256) {
        // safe mint checks id
        uint256 newId = _storeIds++;
        _mint(owner, newId);
        // update the hash
        storeRootHash[newId] = rootHash;
        return newId;
    }

    function updateRootHash(uint256 id, bytes32 hash) public
    {
        authorized(id);
        storeRootHash[id] = hash;
    }

    function updateRelays(uint256 id, string[] memory _relays) public {
        authorized(id);
        relays[id] = _relays;
    }
}
