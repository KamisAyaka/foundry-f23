// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract DeployUtils is Script {
    function deployRebaseTokenAndPool(
        uint256 fork,
        address owner,
        CCIPLocalSimulatorFork ccipLocalSimulatorFork
    )
        public
        returns (
            RebaseToken token,
            RebaseTokenPool pool,
            Register.NetworkDetails memory networkDetails
        )
    {
        vm.selectFork(fork);
        networkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        vm.startBroadcast(owner);
        token = new RebaseToken();
        pool = new RebaseTokenPool(
            IERC20(address(token)),
            new address[](0),
            networkDetails.rmnProxyAddress,
            networkDetails.routerAddress
        );
        token.grantMintAndBurnRole(address(pool));
        RegistryModuleOwnerCustom(
            networkDetails.registryModuleOwnerCustomAddress
        ).registerAdminViaOwner(address(token));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress)
            .acceptAdminRole(address(token));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress).setPool(
            address(token),
            address(pool)
        );
        vm.stopBroadcast();
    }

    function deployVault(
        uint256 fork,
        address owner,
        address rebaseToken
    ) public returns (Vault vault) {
        vm.selectFork(fork);
        vm.startBroadcast(owner);
        vault = new Vault(IRebaseToken(rebaseToken));
        IRebaseToken(rebaseToken).grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
    }
}
