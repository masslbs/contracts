// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RelayReg is ERC721 {
    uint256 private _relayIds;

    constructor() ERC721("RelayRegistry", "RR") {}

    mapping(uint256 => string) public relayURIs;

    function mint(uint256 newRelayId, address relay, string memory uri) public {
        _mint(relay, newRelayId);
        relayURIs[newRelayId] = uri;
    }

    function updateURI(uint256 relayId, string memory uri) public {
        require(ownerOf(relayId) == msg.sender, "NOT_AUTHORIZED");
        relayURIs[relayId] = uri;
    }

    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return relayURIs[id];
    }
}
