// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// import DAO role
contract INOTransferHelper {
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external {
        token.safeTransferFrom(from, to, id, value, data);
    }
}
