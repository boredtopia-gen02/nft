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
        bytes32 hash,
        uint credit
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintCredit[hash] += credit;
    }

    function grantFreeMintQuota(bytes32 hash) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _freeMintUsed[hash] = false;
    }

    function getMintCredit(bytes32 hash) public view returns (uint) {
        return _mintCredit[hash];
    }

    function getHasFreeMintQuota(bytes32 hash) public view returns (bool) {
        return !_freeMintUsed[hash];
    }

    function mint() external whenNotPaused {
        bytes32 hashAddr = keccak256(bytes(Strings.toHexString(msg.sender)));
        require(
            !_freeMintUsed[hashAddr] || _mintCredit[hashAddr] > 0,
            "This address has already claimed its free mint and has no more mint credits."
        );

        nft.mint(msg.sender);

        if (!_freeMintUsed[hashAddr]) {
            _freeMintUsed[hashAddr] = true;
        } else {
            _mintCredit[hashAddr]--;
        }
    }
}
