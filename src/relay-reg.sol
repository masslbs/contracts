// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract RelayReg is ERC721URIStorage {
    uint256 private _relayIds;

    constructor() ERC721("RelayReg", "MMRR") {}

    function mint(address owner, string memory uri)
        public
        returns (uint256)
    {
        uint256 newRelayId = _relayIds++;
        _mint(owner, newRelayId);
        _setTokenURI(newRelayId, uri);

        return newRelayId;
    }
}
