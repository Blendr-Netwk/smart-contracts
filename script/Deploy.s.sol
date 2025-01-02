// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Blendr_Token.sol";
import "../src/Reward_Distributor.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Blendr token = new Blendr(1000000);
        // console.log("BLENDR deployed at:", address(token));
        address tokenAddress=0xd0740792b3a2778628f53561bB20150b81E2540D;
        address serverAddress = vm.envAddress("SERVER_ADDRESS");
        RewardDistributor rewardDistributor = new RewardDistributor(serverAddress, address(tokenAddress));
        console.log("RewardDistributor deployed at:", address(rewardDistributor));

        vm.stopBroadcast();
    }
}