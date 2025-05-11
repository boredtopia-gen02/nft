// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface INft {
    function mint(address account) external;
}

contract PaidMinter is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public mintPrice = 2 ether; // SEI
    address public platformWallet;
    INft public nft;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        platformWallet = msg.sender;
    }

    // flow control
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // minting config
    function setNFT(
        address _address
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Invalid address");
        nft = INft(_address);
    }
    function setMintPrice(
        uint256 _price
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _price;
    }
    function setPlatformWallet(
        address _wallet
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        platformWallet = _wallet;
    }

    // paid mint
    function mint(uint256 amount) external payable whenNotPaused {
        uint256 totalPrice = mintPrice * amount;
        require(msg.value >= totalPrice, "Insufficient funds");

        // handle money
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        payable(platformWallet).transfer(totalPrice);

        for (uint256 i = 0; i < amount; i++) {
            nft.mint(msg.sender);
        }
    }
}
