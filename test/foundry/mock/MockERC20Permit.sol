// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MockERC20Permit is ERC20Permit {
    uint8 private immutable _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 demicals_
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _decimals = demicals_;
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
