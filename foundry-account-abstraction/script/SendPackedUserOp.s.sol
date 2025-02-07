// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    // 主运行函数，用于生成并发送打包的用户操作（UserOperation）
    function run() public {
        HelperConfig helperConfig = new HelperConfig(); // 创建HelperConfig实例以获取网络配置
        address dest = helperConfig.getConfig().account; // 获取目标地址
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            IERC20.approve.selector, // 编码ERC20的approve方法调用数据
            dest,
            1e18
        );
        bytes memory executeCalldata = abi.encodeWithSelector(
            MinimalAccount.execute.selector, // 编码MinimalAccount的execute方法调用数据
            dest,
            value,
            functionData
        );
        PackedUserOperation memory userOp = generateSignedUserOperation(
            executeCalldata,
            helperConfig.getConfig(),
            address(0)
        ); // 生成并签名用户操作
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.startBroadcast(); // 开始广播交易
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            ops,
            payable(helperConfig.getConfig().account) // 处理用户操作并支付给指定账户
        );
        vm.stopBroadcast(); // 停止广播交易
    }

    // 生成并签名用户操作
    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        uint256 nonce = vm.getNonce(minimalAccount) - 1; // 获取nonce并减1
        //在Forge虚拟机中，vm.getNonce 返回的是下一个将要使用的Nonce值，而不是当前已使用的Nonce值。因此，为了与实际合约状态保持一致，我们需要减1来获取当前的Nonce值。
        // 1. 生成未签名的数据
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(
            callData,
            minimalAccount,
            nonce
        );
        // 2. 获取用户操作的哈希值
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            userOp
        );
        bytes32 digest = userOpHash.toEthSignedMessageHash(); // 将哈希转换为以太坊签名消息哈希

        // 3. 签名未签名的数据并返回
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            // 如果在本地链（Anvil）上
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest); // 使用默认私钥签名
        } else {
            (v, r, s) = vm.sign(config.account, digest); // 使用配置中的账户签名
        }
        userOp.signature = abi.encodePacked(r, s, v); // 按顺序编码r, s, v作为签名
        return userOp;
    }

    // 生成未签名的用户操作
    function _generateUnsignedUserOperation(
        bytes memory callData,
        address sender,
        uint256 nonce
    ) internal pure returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216; // 设置验证气体限制
        uint128 callGasLimit = verificationGasLimit; // 设置调用气体限制
        uint128 maxPriorityFeePerGas = 256; // 设置最大优先费用每单位气体
        uint256 maxFeePerGas = maxPriorityFeePerGas; // 设置最大费用每单位气体
        return
            PackedUserOperation({
                sender: sender, // 发送者地址
                nonce: nonce, // 非重复数
                initCode: hex"", // 初始化代码（空）
                callData: callData, // 调用数据
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) | callGasLimit
                ), // 设置账户气体限制
                preVerificationGas: verificationGasLimit, // 设置预验证气体限制
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ), // 设置气体费用
                paymasterAndData: hex"", // 支付人和数据（空）
                signature: hex"" // 签名（空）
            });
    }
}
