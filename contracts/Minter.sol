// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface INft {
    function mint(address account) external;
}

contract Minter is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    INft public nft;

    mapping(bytes32 => bool) private _freeMintUsed;
    mapping(bytes32 => uint) private _mintCredit;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    modifier canMint(address address_) {
        bytes32 hashAddr = keccak256(bytes(Strings.toHexString(address_)));
        require(
            !_freeMintUsed[hashAddr] || _mintCredit[hashAddr] > 0,
            "This address has already claimed its free mint and has no more mint credits."
        );
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setNFT(
        address address_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address_ != address(0), "Invalid address.");
        nft = INft(address_);
    }

    function addMintCredit(
        address user,
        uint credit
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintCredit[keccak256(bytes(Strings.toHexString(user)))] += credit;
    }

    function grantFreeMintQuota( address user ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _freeMintUsed[keccak256(bytes(Strings.toHexString(user)))] = false;
    }

    function getMintCredit(address user) public view returns (uint) {
        return _mintCredit[keccak256(bytes(Strings.toHexString(user)))];
    }

    function getHasFreeMintQuota(address user) public view returns (bool) {
        return !_freeMintUsed[keccak256(bytes(Strings.toHexString(user)))];
    }

    function mint() external whenNotPaused canMint(msg.sender) {
        nft.mint(msg.sender);

        bytes32 hashAddr = keccak256(bytes(Strings.toHexString(msg.sender)));
        if (!_freeMintUsed[hashAddr]) {
            _freeMintUsed[hashAddr] = true;
        } else {
            _mintCredit[hashAddr]--;
        }
    }
}
