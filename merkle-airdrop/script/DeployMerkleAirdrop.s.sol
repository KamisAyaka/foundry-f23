// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {DogeToken} from "../src/DogeToken.sol";
import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private s_merkleRoot =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private s_amountToTransfer = 4 * 25 * 1e18;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, DogeToken) {
        vm.startBroadcast();
        DogeToken dogeToken = new DogeToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(
            s_merkleRoot,
            IERC20(address(dogeToken))
        );
        dogeToken.mint(dogeToken.owner(), s_amountToTransfer);
        dogeToken.transfer(address(merkleAirdrop), s_amountToTransfer);
        vm.stopBroadcast();
        return (merkleAirdrop, dogeToken);
    }

    function run() external returns (MerkleAirdrop, DogeToken) {
        return deployMerkleAirdrop();
    }
}
