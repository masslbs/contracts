// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { ERC721 } from "solady/src/tokens/ERC721.sol";

contract RelayReg is ERC721 {
    uint256 private _relayIds;

    constructor() ERC721() {}
    mapping(uint256 => string) public relayURIs;

    function name() public  pure override returns (string memory)
    {
        return "RelayRegestry";
    }

    function symbol() public  pure override returns (string memory)
    {
        return "RR";
    }

    function mint(uint256 newRelayId, address relay, string memory uri) public
    {
        _mint(relay, newRelayId);
        relayURIs[newRelayId] = uri;
    }

    function updateURI(uint256 relayId, string memory uri) public
    {
         require(ownerOf(relayId) == msg.sender, "NOT_AUTHORIZED");
        relayURIs[relayId] = uri;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return relayURIs[id];
    }
}
