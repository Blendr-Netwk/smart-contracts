## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## How to deploy

### Environment Variables Setup

```shell
export PRIVATE_KEY=your_private_key_here
```

```shell
export ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Install Dependencies 
```shell
forge install OpenZeppelin/openzeppelin-contracts
```

### Compile Contracts
```shell
forge build
```

### Deploy Contracts
```shell
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID \
  --broadcast \
  --chain-id 11155111
```

### Encode Constructor Arguments
```shell
cast abi-encode "constructor(uint256)" 1000000
```

### Verify Contract
```shell
forge verify-contract \
  --chain-id 11155111 \
  --compiler-version 0.8.20 \
  0xd0740792b3a2778628f53561bB20150b81E2540D \
  src/Blendr_Token.sol:Blendr \
  --constructor-args 00000000000000000000000000000000000000000000000000000000000f4240
```