// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlphaDAO is ERC20 {
    constructor(address to) ERC20("AlphaDAO", "AlphaDAO") {
        _mint(to, 10000 * 1e8 * 1e18);
    }
}
