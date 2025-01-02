// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Blendr_Token.sol";

contract BLENDRTest is Test {
    Blendr token;
    address owner = address(this);
    address addr1 = address(0x1);

    function setUp() public {
        token = new Blendr(1000);
    }

    function testInitialSupply() public view {
        uint256 ownerBalance = token.balanceOf(owner);
        assertEq(ownerBalance, 1000 * (10 ** token.decimals()));
    }

    function testMinting() public {
        token.mint(addr1, 500);
        uint256 addr1Balance = token.balanceOf(addr1);
        assertEq(addr1Balance, 500 * (10 ** token.decimals()));
    }

    function testBurning() public {
        token.burn(200 * (10 ** token.decimals()));
        uint256 ownerBalance = token.balanceOf(owner);
        assertEq(ownerBalance, 800 * (10 ** token.decimals()));
    }
}