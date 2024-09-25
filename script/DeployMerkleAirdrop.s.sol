// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MerkleAirdrop, IERC20} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 s_merkleRoot =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private s_amountToTransfer = 4 * 25 * 1e18;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken bagelToken = new BagelToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(
            s_merkleRoot,
            IERC20(address(bagelToken))
        );
        bagelToken.mint(bagelToken.owner(), s_amountToTransfer);
        bagelToken.transfer(address(merkleAirdrop), s_amountToTransfer);
        vm.stopBroadcast();
        return (merkleAirdrop, bagelToken);
    }

    function run() external returns (MerkleAirdrop, BagelToken) {
        return deployMerkleAirdrop();
    }
}
