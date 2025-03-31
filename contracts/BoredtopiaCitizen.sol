// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BoredtopiaCitizen is ERC1155, ERC1155Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name = "Boredtopia Citizen";
    string public symbol = "BTC";
    string private baseURI = "https://boredtopia-gen02.github.io/nft/";

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, randomId(), 1, "");
    }

    function randomId() public view returns (uint256) { // 1-5
        return (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))) % 5) + 1;
    }

    // metadata
    function setBaseURI(string calldata _newBaseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "admin only");
        baseURI = _newBaseURI;
    }
    function tokenURI(uint tokenId) public view returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }
    function uri(uint256 id) public view override returns (string memory) {
        return tokenURI(id);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
