// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

/// @title MerkleAirdropTest
/// @notice Test suite for the MerkleAirdrop contract
/// @dev This contract tests various functionalities of the MerkleAirdrop contract,
///      including claiming tokens, preventing double claims, and handling invalid proofs and signatures.
contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    MerkleAirdrop public merkleAirdrop;
    BagelToken public bagelToken;

    bytes32 public ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 proofOne =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    address public gasPayer;
    address user;
    uint256 userPrivateKey;

    /// @notice Set up the test environment
    /// @dev This function deploys the necessary contracts and sets up test accounts
    function setUp() public {
        if (!isZkSyncChain()) {
            // Deploy using the script for non-ZkSync chains
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, bagelToken) = deployer.run();
        } else {
            // Manual deployment for ZkSync chains
            bagelToken = new BagelToken();
            merkleAirdrop = new MerkleAirdrop(ROOT, bagelToken);
            bagelToken.mint(bagelToken.owner(), AMOUNT_TO_SEND);
            bagelToken.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        }
        (user, userPrivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    /// @notice Test that users can successfully claim tokens
    function testUsersCanClaim() public {
        console2.log("user address:", user);

        uint256 startBalance = bagelToken.balanceOf(user);
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        console2.log("start balance:", startBalance);

        // Sign the message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // Simulate gasPayer calling claim using the signed message
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endBalance = bagelToken.balanceOf(user);
        console2.log("end balance:", endBalance);

        assertEq(endBalance - startBalance, AMOUNT_TO_CLAIM);
    }

    /// @notice Test that users cannot claim tokens twice
    function testCannotClaimTwice() public {
        // First claim
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        // Attempt to claim again
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    /// @notice Test that claims with invalid proofs are rejected
    function testCannotClaimWithInvalidProof() public {
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // Use an invalid proof
        bytes32[] memory invalidProof = new bytes32[](2);
        invalidProof[0] = bytes32(0);
        invalidProof[1] = bytes32(0);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, invalidProof, v, r, s);
    }

    /// @notice Test that claims with invalid signatures are rejected
    function testCannotClaimWithInvalidSignature() public {
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey + 1, digest); // Use a different private key

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    /// @notice Test the getMerkleRoot function
    function testGetMerkleRoot() public view {
        assertEq(merkleAirdrop.getMerkleRoot(), ROOT);
    }

    /// @notice Test the getAirdropToken function
    function testGetAirdropToken() public view {
        assertEq(address(merkleAirdrop.getAirdropToken()), address(bagelToken));
    }
}
