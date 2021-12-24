// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/examples/SimpleToken.sol
 */
contract SimpleToken is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("FAKEUSDC", "FUSDC") {
        _mint(msg.sender, 50000*10**6);
    }
    function decimals() override public view returns (uint8) {
        return 6;
    }
    function easy_mint(address recipient) external {
        _mint(recipient, 50000*10**6);
    }
}