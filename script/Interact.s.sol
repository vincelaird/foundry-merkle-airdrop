// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    error ClaimAirdropScript__InvalidSignatureLength();

    address public constant CLAIMING_ADDRESS =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public constant CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 public constant PROOF_ONE =
        0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 public constant PROOF_TWO =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];
    bytes public constant SIGNATURE =
        hex"c8514aa2d6f4233915c99fd6b9f23c3365558278628e02ed82d74ad3ceb52ab327568f42f78810797116baeba4395f783b497ac5b4997a8084d157eb9a367aad1c";

    function getClaimingAddress() public pure returns (address) {
        return CLAIMING_ADDRESS;
    }

    function getClaimingAmount() public pure returns (uint256) {
        return CLAIMING_AMOUNT;
    }

    function getProof() public view returns (bytes32[] memory) {
        return proof;
    }

    function generateSignature(
        address airdropContract
    ) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 messageHash = MerkleAirdrop(airdropContract).getMessageHash(
            CLAIMING_ADDRESS,
            CLAIMING_AMOUNT
        );
        (v, r, s) = vm.sign(vm.envUint("ANVIL_PRIVATE_KEY"), messageHash);
    }

    function claimAirdrop(address airdrop) public {
        if (airdrop == address(0)) {
            // This is a mock address, return
            return;
        }
        // (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE); // change for testClaimAirdrop test
        (uint8 v, bytes32 r, bytes32 s) = generateSignature(airdrop);
        MerkleAirdrop(airdrop).claim(
            CLAIMING_ADDRESS,
            CLAIMING_AMOUNT,
            getProof(),
            v,
            r,
            s
        );
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert ClaimAirdropScript__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        vm.startBroadcast();
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MerkleAirdrop",
            block.chainid
        );
        claimAirdrop(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}
