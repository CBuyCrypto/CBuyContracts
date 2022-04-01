// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract cUSD is ERC20 {
    constructor() ERC20("Celo Dolor", "cUSD") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}