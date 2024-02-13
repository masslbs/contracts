// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// aka "Eddies" - a reference to cyberpunk 2077
contract EuroDollarToken is ERC20 {

    constructor (string memory _name, string memory _symbol) ERC20 (_name,_symbol){
    }

    function mint(address to, uint256 amount) public virtual {
        _mint(to,amount);
    }

    function burn(address form, uint amount) public virtual {
        _burn(form, amount);
    }
}