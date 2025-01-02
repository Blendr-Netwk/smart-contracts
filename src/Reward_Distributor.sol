// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RewardDistributor is Ownable, ReentrancyGuard {
    // Server address for signature verification
    address public serverAddress;

    // Reward token
    address public rewardTokenAddress;

    // Configurable claim time limit with getter and setter
    uint256 private _claimTimeLimit = 3600; // 1 hour default
    
    // Mapping to track user nonces and claimed rewards
    mapping(address => uint256) public userNonce;
    mapping(address => uint256) public rewardsClaimed;

    // Events
    event RewardClaimed(address indexed user, uint256 amount);
    event ServerAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event RewardTokenUpdated(address indexed oldToken, address indexed newToken);
    event ClaimTimeLimitUpdated(uint256 oldLimit, uint256 newLimit);

    // Constructor
    constructor(address _serverAddress, address _rewardTokenAddress) Ownable(msg.sender) {
        require(_serverAddress != address(0), "Invalid server address");
        
        serverAddress = _serverAddress;
        rewardTokenAddress = _rewardTokenAddress;
    }

    // Getter for claim time limit
    function claimTimeLimit() public view returns (uint256) {
        return _claimTimeLimit;
    }

    // Setter for claim time limit (only owner)
    function setClaimTimeLimit(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Time limit must be greater than 0");
        emit ClaimTimeLimitUpdated(_claimTimeLimit, newLimit);
        _claimTimeLimit = newLimit;
    }

    // Update server address
    function updateServerAddress(address newServerAddress) external onlyOwner {
        require(newServerAddress != address(0), "Invalid server address");
        emit ServerAddressUpdated(serverAddress, newServerAddress);
        serverAddress = newServerAddress;
    }

    // Update reward token
    function updateRewardToken(address newTokenAddress) external onlyOwner {
        emit RewardTokenUpdated(rewardTokenAddress, newTokenAddress);
        rewardTokenAddress = newTokenAddress;
    }

    function claimReward(
        uint256 amount,
        uint256 nonce,
        uint256 timestamp,
        bytes memory signature
    ) external nonReentrant {
        // Check signature expiration
        require(block.timestamp - timestamp <= _claimTimeLimit, "Signature expired");

        // Validate nonce
        require(nonce == userNonce[msg.sender], "Invalid nonce");

        // Prepare and hash message
        bytes32 message = keccak256(abi.encodePacked(msg.sender, amount, nonce, timestamp));
        bytes32 messageHash = prefixed(message);

        // Verify signature
        require(recoverSigner(messageHash, signature) == serverAddress, "Invalid signature");

        // Check contract balance
        if (rewardTokenAddress == address(0)) {
            // Native token
            require(address(this).balance >= amount, "Insufficient contract balance");
            
            // Transfer native token
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Native token transfer failed");
        } else {
            // ERC20 token claim
            IERC20 token = IERC20(rewardTokenAddress);
            require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
            
            // Transfer ERC20 token
            bool success = token.transfer(msg.sender, amount);
            require(success, "Token transfer failed");
        }

        // Update user's claimed rewards
        rewardsClaimed[msg.sender] += amount;

        // Increment nonce to prevent replay attacks
        userNonce[msg.sender]++;

        // Emit event
        emit RewardClaimed(msg.sender, amount);
    }

    // Allow contract to receive native tokens
    receive() external payable {}

    // Withdraw stuck tokens or native tokens (emergency function)
    function withdrawStuckTokens(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw native tokens
            payable(owner()).transfer(amount);
        } else {
            // Withdraw ERC20 tokens
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(owner(), amount), "Token transfer failed");
        }
    }

    // Signature recovery functions
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}