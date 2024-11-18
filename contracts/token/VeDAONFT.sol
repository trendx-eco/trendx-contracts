// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VeDAONFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    string private _baseURIextended;

    struct User {
        address entry;
        string uri;
        string level;
        bool status;
    }
    mapping(address => mapping(string => User)) private allowList;
    string[] private levelList;

    constructor() ERC721("Vedao", "Dao888") {}

    function addLevel(string memory level) external onlyOwner {
        levelList.push(level);
    }

    function getLevel(uint256 index) public view returns (string memory) {
        return levelList[index];
    }

    function getLevelListLength() public view returns (uint256) {
        return levelList.length;
    }

    function hashCompareWithLengthCheck(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return
                keccak256(abi.encodePacked(a)) ==
                keccak256(abi.encodePacked(b));
        }
    }

    function checkLevel(string memory level) private view returns (bool) {
        bool result = false;
        for (uint256 i = 0; i < getLevelListLength(); i++) {
            if (hashCompareWithLengthCheck(getLevel(i), level)) {
                result = true;
            }
        }
        return result;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mintAllowList(string memory level) public {
        require(checkLevel(level), "level isn't found");
        require(
            allowList[msg.sender][level].entry != address(0),
            "address not exists"
        );
        require(allowList[msg.sender][level].status == true, "NFT is obtained");
        // start minting
        allowList[msg.sender][level].status = false;
        uint256 nextSupply = totalSupply() + 1;
        _safeMint(msg.sender, nextSupply);
        _setTokenURI(nextSupply, allowList[msg.sender][level].uri);
    }

    function addAllowList(
        address _newEntry,
        string memory uri,
        string memory level
    ) external onlyOwner {
        require(
            allowList[_newEntry][level].entry == address(0),
            "address already exists"
        );
        require(checkLevel(level), "level isn't found");
        allowList[_newEntry][level].entry = _newEntry;
        allowList[_newEntry][level].uri = uri;
        allowList[_newEntry][level].level = level;
        allowList[_newEntry][level].status = true;
    }

    function removeAllowList(
        address _newEntry,
        string memory level
    ) external onlyOwner {
        require(
            allowList[_newEntry][level].entry != address(0),
            "address not exists"
        );
        allowList[_newEntry][level].status = false;
    }

    function updateAllowList(
        address _newEntry,
        string memory uri,
        string memory level
    ) external onlyOwner {
        require(
            allowList[_newEntry][level].entry != address(0),
            "address not exists"
        );
        allowList[_newEntry][level].entry = _newEntry;
        allowList[_newEntry][level].uri = uri;
        allowList[_newEntry][level].level = level;
        allowList[_newEntry][level].status = true;
    }

    function getAllowList(
        address _newEntry,
        string memory level
    ) public view returns (User memory) {
        return allowList[_newEntry][level];
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
