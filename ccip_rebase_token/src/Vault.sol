// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    IRebaseToken private immutable i_rebaseToken;

    error Vault__RedeemFailed();
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    /**
     * @notice 构造函数，初始化 Vault 合约。
     * @param _rebaseToken RebaseToken 合约地址。
     */
    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    /**
     * @notice 存入 ETH 到金库并铸造复利代币。
     */
    function deposit() external payable {
        // 存入 ETH 到金库
        // 铸造代币给用户
        // 触发 Deposit 事件
        uint256 interestRate = i_rebaseToken.getInterestRate();
        i_rebaseToken.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 用复利代币兑换 ETH。
     * @param _amount 要兑换的代币数量。
     */
    function redeem(uint256 _amount) external {
        // 燃烧用户的代币
        // 从金库中提取 ETH
        // 触发 Redeem 事件
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice 返回金库使用的复利代币地址。
     */
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
