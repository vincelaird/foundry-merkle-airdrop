# Merkle Airdrop Project

This project implements a Merkle tree-based airdrop system for token distribution using Solidity and Foundry.
Based on https://github.com/Cyfrin/foundry-merkle-airdrop-cu

## Overview

The Merkle Airdrop system allows for efficient and gas-optimized token distribution to a large number of recipients. It uses a Merkle tree to verify claims without storing all recipient data on-chain.

## Key Components

1. **MerkleAirdrop Contract**: The main contract that handles the airdrop logic.
2. **BagelToken**: An ERC20 token used for the airdrop.
3. **Scripts**: Helper scripts for generating input, creating Merkle trees, and interacting with the contracts.
4. **Tests**: Comprehensive test suite for all components.

## Folder Structure

- `script/`: Contains deployment and interaction scripts.
- `src/`: Source code for the main contracts.
- `test/`: Test files for all contracts and scripts.

## Test coverage

| File                             | % Lines         | % Statements      | % Branches      | % Funcs        |
|----------------------------------|-----------------|-------------------|-----------------|----------------|
| script/DeployMerkleAirdrop.s.sol | 100.00% (9/9)   | 100.00% (11/11)   | 100.00% (0/0)   | 50.00% (1/2)   |
| script/GenerateInput.s.sol       | 100.00% (21/21) | 100.00% (26/26)   | 100.00% (2/2)   | 100.00% (2/2)  |
| script/Interact.s.sol            | 100.00% (18/18) | 100.00% (21/21)   | 100.00% (2/2)   | 100.00% (7/7)  |
| script/MakeMerkle.s.sol          | 100.00% (29/29) | 100.00% (42/42)   | 100.00% (3/3)   | 100.00% (3/3)  |
| src/BagelToken.sol               | 100.00% (1/1)   | 100.00% (1/1)     | 100.00% (0/0)   | 100.00% (2/2)  |
| src/MerkleAirdrop.sol            | 100.00% (17/17) | 100.00% (20/20)   | 100.00% (3/3)   | 100.00% (6/6)  |
| Total                            | 100.00% (95/95) | 100.00% (121/121) | 100.00% (10/10) | 95.45% (21/22) |

To run the tests:
```
forge test
```

To run the tests with coverage:
```
forge coverage
```

## Usage

1. Deploy the BagelToken and MerkleAirdrop contracts.
2. Generate the Merkle tree using the `MakeMerkle` script.
3. Users can claim their tokens by providing a valid Merkle proof.

## Scripts

- `GenerateInput.s.sol`: Generates input data for the Merkle tree.
- `MakeMerkle.s.sol`: Creates the Merkle tree from input data.
- `Interact.s.sol`: Provides functions to interact with the deployed contracts.

## License

This project is licensed under the MIT License.
