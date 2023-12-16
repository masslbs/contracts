// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract RelayReg is ERC721URIStorage {
    uint256 private _relayIds;

    constructor() ERC721("RelayReg", "MMRR") {}

    function registerRelay(uint256 newRelayId, address relay, string memory uri) public
    {
        _safeMint(relay, newRelayId);
        _setTokenURI(newRelayId, uri);
    }

    function updateURI(uint256 relayId, string memory uri) public
    {
         require(_ownerOf(relayId) == _msgSender(), "NOT_AUTHORIZED");
        _setTokenURI(relayId, uri);
    }
}
