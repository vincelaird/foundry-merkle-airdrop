// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ClaimAirdrop} from "../script/Interact.s.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Vm} from "forge-std/Vm.sol";

/// @title ClaimAirdropTest
/// @notice Test suite for the ClaimAirdrop contract
/// @dev These tests use a combination of mocking and hardcoded values to simulate
///      the deployment and execution of the ClaimAirdrop script in a controlled environment.
///      This approach is necessary because:
///      1. The test environment doesn't persist state between runs, so we need to set up
///         the initial state (e.g., funding the MerkleAirdrop contract) in each test.
///      2. We want to ensure consistent behavior across different test runs and environments,
///         which requires using hardcoded addresses and mocking external calls.
///      3. The main focus is on testing the wrapper functionality of the ClaimAirdrop script,
///         rather than testing the deployment process or external dependencies.
contract ClaimAirdropTest is Test {
    ClaimAirdrop public claimAirdrop;
    MerkleAirdrop public merkleAirdrop;
    BagelToken public bagelToken;

    /// @notice Set up the test environment
    /// @dev This function is called before each test
    function setUp() public {
        claimAirdrop = new ClaimAirdrop();
        bagelToken = new BagelToken();

        // Use a hardcoded Merkle root for consistency across tests
        bytes32 merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
        merkleAirdrop = new MerkleAirdrop(merkleRoot, bagelToken);

        // Fund the MerkleAirdrop contract
        bagelToken.mint(address(this), 100 * 1e18);
        bagelToken.transfer(address(merkleAirdrop), 100 * 1e18);

        // Set up the environment variable for the private key
        vm.setEnv(
            "ANVIL_PRIVATE_KEY",
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );
    }

    /// @notice Test the claimAirdrop function
    /// @dev This test verifies that the claimAirdrop function correctly transfers tokens
    ///      from the MerkleAirdrop contract to the claiming address.
    function testClaimAirdrop() public {
        address claimingAddress = claimAirdrop.getClaimingAddress();
        uint256 claimingAmount = claimAirdrop.getClaimingAmount();

        uint256 initialBalance = bagelToken.balanceOf(claimingAddress);

        // Mock the DevOpsTools.get_most_recent_deployment function
        vm.mockCall(
            address(0),
            abi.encodeWithSignature(
                "get_most_recent_deployment(string,uint256)"
            ),
            abi.encode(address(merkleAirdrop))
        );

        // Call claimAirdrop directly
        claimAirdrop.claimAirdrop(address(merkleAirdrop));

        uint256 finalBalance = bagelToken.balanceOf(claimingAddress);
        assertEq(finalBalance - initialBalance, claimingAmount);
    }

    /// @notice Test the splitSignature function
    /// @dev This test verifies that the signature is correctly split into its components
    function testSplitSignature() public view {
        (uint8 v, bytes32 r, bytes32 s) = claimAirdrop.splitSignature(
            claimAirdrop.SIGNATURE()
        );
        assertEq(v, 28);
        assertEq(
            r,
            0xc8514aa2d6f4233915c99fd6b9f23c3365558278628e02ed82d74ad3ceb52ab3
        );
        assertEq(
            s,
            0x27568f42f78810797116baeba4395f783b497ac5b4997a8084d157eb9a367aad
        );
    }

    /// @notice Test the getProof function
    /// @dev This test verifies that the correct Merkle proof is returned
    function testGetProof() public view {
        bytes32[] memory proof = claimAirdrop.getProof();
        assertEq(proof.length, 2);
        assertEq(proof[0], claimAirdrop.PROOF_ONE());
        assertEq(proof[1], claimAirdrop.PROOF_TWO());
    }

    /// @notice Test the splitSignature function with an invalid signature
    /// @dev This test verifies that the function reverts with the correct error for an invalid signature
    function testInvalidSignatureLength() public {
        bytes memory invalidSignature = hex"1234";
        vm.expectRevert(
            ClaimAirdrop.ClaimAirdropScript__InvalidSignatureLength.selector
        );
        claimAirdrop.splitSignature(invalidSignature);
    }

    /// @notice Test the run() function of the ClaimAirdrop contract
    /// @dev This test simulates the deployment and execution of the ClaimAirdrop script
    ///      in a controlled environment. It uses hardcoded values and mocking to ensure
    ///      consistent behavior across test runs.
    function testRun() public {
        // Hardcode the address for the MerkleAirdrop contract
        // This is necessary because the actual deployment address may vary in different environments
        address hardcodedAddress = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

        // Deploy a new MerkleAirdrop contract at the hardcoded address
        // We use vm.etch() to ensure the contract exists at the expected address
        // This simulates a pre-deployed contract that the ClaimAirdrop script would interact with
        vm.etch(hardcodedAddress, address(merkleAirdrop).code);

        // Fund the MerkleAirdrop contract with tokens
        // This is necessary because the test environment doesn't persist state between runs
        // In a real deployment, the contract would be funded separately
        bagelToken.mint(hardcodedAddress, 100 * 1e18);

        // Set up the environment variable for ANVIL_PRIVATE_KEY
        // This simulates the private key that would be used in a real deployment scenario
        vm.setEnv(
            "ANVIL_PRIVATE_KEY",
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );

        // Mock the DevOpsTools.get_most_recent_deployment function
        // This is necessary because we can't rely on actual deployment files in the test environment
        // We return our hardcoded address to simulate finding the most recent deployment
        vm.mockCall(
            address(0),
            abi.encodeWithSignature(
                "get_most_recent_deployment(string,uint256)"
            ),
            abi.encode(hardcodedAddress)
        );

        // Call run() function
        // This executes the main logic of the ClaimAirdrop script
        claimAirdrop.run();

        // Verify the airdrop was claimed successfully
        // We check that the claiming address received the expected amount of tokens
        assertEq(
            bagelToken.balanceOf(claimAirdrop.getClaimingAddress()),
            25 * 1e18
        );
    }

    /// @notice Test the generateSignature function
    /// @dev This test verifies that the generated signature can be used to recover the correct signer
    function testGenerateSignature() public view {
        (uint8 v, bytes32 r, bytes32 s) = claimAirdrop.generateSignature(
            address(merkleAirdrop)
        );

        bytes32 messageHash = merkleAirdrop.getMessageHash(
            claimAirdrop.getClaimingAddress(),
            claimAirdrop.getClaimingAmount()
        );

        address recoveredSigner = ecrecover(messageHash, v, r, s);
        assertEq(recoveredSigner, claimAirdrop.getClaimingAddress());
    }
}
