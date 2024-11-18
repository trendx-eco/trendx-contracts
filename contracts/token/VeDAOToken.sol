// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract VeDAOToken is ERC20Permit, Ownable {
    uint256 public constant MAX_SUPPLY = 10 * 1e8 * 1e18; //10 B

    constructor(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol,
        address _to
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(_initialSupply <= MAX_SUPPLY, "overflow");
        _mint(_to, _initialSupply);
    }

    //1. private recruitment

    //2. Public recruitment
    //3. airdrop
    //4. stake
    //5. teams
}
