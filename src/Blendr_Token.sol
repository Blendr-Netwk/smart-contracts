// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Blendr is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 initialSupply) ERC20("BLENDR", "BLENDR") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    /**
     * @dev Mints new tokens.
     * Can only be called by the contract owner.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint (without considering decimals).
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * (10 ** decimals()));
    }

    /**
     * @dev Burns tokens from the owner's account.
     * Can only be called by the contract owner.
     * @param amount The amount of tokens to burn (without considering decimals).
     */
    function burn(uint256 amount) public override onlyOwner {
        _burn(msg.sender, amount * (10 ** decimals()));
    }

    /**
     * @dev Burns tokens from a specified address.
     * Can only be called by the contract owner.
     * @param account The address from which to burn tokens.
     * @param amount The amount of tokens to burn (without considering decimals).
     */
    function burnFrom(address account, uint256 amount) public override onlyOwner {
        _burn(account, amount * (10 ** decimals()));
    }
}