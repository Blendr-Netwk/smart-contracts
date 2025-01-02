// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GPURental is ReentrancyGuard, Ownable {
    // Rental struct to store rental details
    struct Rental {
        address renter;          // Address of the person renting
        address provider;        // GPU provider address
        uint256 startTime;       // Start timestamp
        uint256 duration;        // Duration in hours
        uint256 amount;          // Total amount deposited
    }

    // Server address for signature verification
    address public serverAddress;

    // Configurable claim time limit with getter and setter
    uint256 private _claimTimeLimit = 3600; // 1 hour default

    // State variables
    mapping(uint256 => Rental) public rentals;  // Rental ID to Rental mapping
    uint256 public nextRentalId;             // Counter for rental IDs
    
    // Mapping to track user nonces
    mapping(address => uint256) public userNonce;

    // Mapping of provider addresses to their amounts
    mapping(address => uint256) public providerAmounts;

    // Events
    event ClaimTimeLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event ServerAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event Deposited(uint256 indexed rentalId, address indexed renter, address indexed provider, uint256 duration, uint256 amount);
    event Claimed(address indexed provider, uint256 amount);
    event Refunded(address indexed renter, uint256 amount);

    constructor(address _serverAddress) Ownable(msg.sender) {
        require(_serverAddress != address(0), "Invalid server address");
        serverAddress = _serverAddress;
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

    // Deposit
    function deposit(address provider, uint256 duration) external payable nonReentrant {
        require(provider != address(0), "Invalid provider address");
        require(msg.value > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

         // Create new rental
        uint256 rentalId = nextRentalId++;
        rentals[rentalId] = Rental({
            renter: msg.sender,
            provider: provider,
            startTime: block.timestamp,
            duration: duration,
            amount: msg.value
        });

        // Increase the provider's amount
        providerAmounts[provider] += msg.value;

        emit Deposited(rentalId, msg.sender, provider, duration, msg.value);
    }

    // Claim
    function claim(
        uint256 amount, 
        uint256 nonce,
        uint256 timestamp,
        bytes memory sig
    ) external nonReentrant {
        address provider = msg.sender; // Assuming the caller is the provider
        require(providerAmounts[provider] >= amount, "Insufficient amount to claim");

        // Check signature expiration
        require(block.timestamp - timestamp <= _claimTimeLimit, "Signature expired");

        // Validate nonce
        require(nonce == userNonce[msg.sender], "Invalid nonce");

        // Verify the signature
        bytes32 message = prefixed(keccak256(abi.encodePacked(provider, amount, nonce, timestamp)));
        address signer = recoverSigner(message, sig);
        require(signer == serverAddress, "Invalid signature");

        // Increment nonce to prevent replay attacks
        userNonce[msg.sender]++;

        // Decrease the provider's amount
        providerAmounts[provider] -= amount;

        // Transfer the amount to the provider
        payable(provider).transfer(amount);

        emit Claimed(provider, amount);
    }

    // Refund
    function refund(
        address renter, 
        uint256 amount,
        uint256 nonce,
        uint256 timestamp,
        bool isRefund,
        bytes memory sig
    ) external nonReentrant {
        require(providerAmounts[renter] >= amount, "Insufficient amount to refund");
        
        // Check signature expiration
        require(block.timestamp - timestamp <= _claimTimeLimit, "Signature expired");

        // Validate nonce
        require(nonce == userNonce[msg.sender], "Invalid nonce");

        // Verify the signature
        bytes32 message = prefixed(keccak256(abi.encodePacked(renter, amount, nonce, timestamp, isRefund)));
        address signer = recoverSigner(message, sig);
        require(signer == serverAddress, "Invalid signature");

        // Increment nonce to prevent replay attacks
        userNonce[msg.sender]++;

        // Decrease the provider's amount
        providerAmounts[renter] -= amount;

        // Transfer the amount back to the renter
        payable(renter).transfer(amount);

        emit Refunded(renter, amount);
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