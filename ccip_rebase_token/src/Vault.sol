// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    IRebaseToken private immutable i_rebaseToken;

    error Vault__RedeemFailed();
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    /**
     * @notice Deposit ETH into the vault and mint rebase tokens.
     */
    function deposit() external payable {
        // Deposit ETH into the vault
        // Mint tokens to the user
        // Emit a Deposit event
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Redeem rebase tokens for ETH.
     * @param _amount The amount of tokens to redeem.
     */
    function redeem(uint256 _amount) external {
        // Burn tokens from the user
        // Withdraw ETH from the vault
        // Emit a Redeem event
        i_rebaseToken.burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice Returns the address of the rebase token used by the vault.
     */
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
