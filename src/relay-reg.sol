// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";

contract RelayReg is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _relayIds;

    constructor() ERC721("RelayReg", "MMRR") {}

    function mintTo(address owner, string memory uri)
        public
        returns (uint256)
    {
        uint256 newRelayId = _relayIds.current();
        _mint(owner, newRelayId);
        _setTokenURI(newRelayId, tokenURI);

        _tokenIds.increment();
        return newItemId;
    }
}
