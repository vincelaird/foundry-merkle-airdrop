// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {GenerateInput} from "../script/GenerateInput.s.sol";
import {ClaimAirdrop} from "../script/Interact.s.sol";
import {MakeMerkle} from "../script/MakeMerkle.s.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

/// @title ScriptsTest
/// @notice Test suite for the scripts used in the MerkleAirdrop project
/// @dev This contract tests the functionality of various scripts used for generating input,
///      creating Merkle trees, and claiming airdrops.
contract ScriptsTest is Test {
    GenerateInput public generateInput;
    ClaimAirdrop public claimAirdrop;
    MakeMerkle public makeMerkle;
    MerkleAirdrop public merkleAirdrop;
    BagelToken public bagelToken;

    /// @notice Set up the test environment
    /// @dev This function initializes the necessary contracts and scripts for testing
    function setUp() public {
        generateInput = new GenerateInput();
        claimAirdrop = new ClaimAirdrop();
        makeMerkle = new MakeMerkle();

        // Deploy MerkleAirdrop and BagelToken for testing
        bagelToken = new BagelToken();
        merkleAirdrop = new MerkleAirdrop(bytes32(0), bagelToken);
    }

    /// @notice Test the GenerateInput script
    /// @dev Verifies that the input file is generated and not empty
    function testGenerateInput() public {
        generateInput.run();
        string memory inputPath = "/script/target/input.json";
        string memory input = vm.readFile(
            string.concat(vm.projectRoot(), inputPath)
        );
        assertTrue(bytes(input).length > 0, "Input file should not be empty");
    }

    /// @notice Test the MakeMerkle script
    /// @dev Verifies that the output file is generated and not empty
    function testMakeMerkle() public {
        makeMerkle.run();
        string memory outputPath = "/script/target/output.json";
        string memory output = vm.readFile(
            string.concat(vm.projectRoot(), outputPath)
        );
        assertTrue(bytes(output).length > 0, "Output file should not be empty");
    }
}
