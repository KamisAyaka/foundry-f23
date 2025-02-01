// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {DeployUtils} from "../script/DeployUtils.s.sol";
import {ConfigurePoolScript} from "../script/ConfigurePool.s.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract CrossChainTest is Test {
    address owner = makeAddr("owner"); // 定义合约所有者地址
    address user = makeAddr("user"); // 定义用户地址
    uint256 SEND_VALUE = 1e5; // 定义发送的金额

    uint256 sepoliaFork; // Sepolia 网络的 fork ID
    uint256 arbSepoliaFork; // Arbitrum Sepolia 网络的 fork ID

    CCIPLocalSimulatorFork ccipLocalSimulatorFork; // CCIP 本地模拟器

    RebaseToken sepoliaToken; // Sepolia 网络上的 RebaseToken
    RebaseToken arbSepoliaToken; // Arbitrum Sepolia 网络上的 RebaseToken

    Vault vault; // 钱包合约

    RebaseTokenPool sepoliaPool; // Sepolia 网络上的 RebaseTokenPool
    RebaseTokenPool arbSepoliaPool; // Arbitrum Sepolia 网络上的 RebaseTokenPool

    Register.NetworkDetails sepoliaNetworkDetails; // Sepolia 网络的详细信息
    Register.NetworkDetails arbSepoliaNetworkDetails; // Arbitrum Sepolia 网络的详细信息

    DeployUtils deployUtils; // 部署工具

    // 测试环境设置
    function setUp() public {
        deployUtils = new DeployUtils(); // 初始化部署工具

        // 创建 Sepolia 和 Arbitrum Sepolia 的 fork
        sepoliaFork = vm.createSelectFork("sepolia-eth");
        arbSepoliaFork = vm.createFork("arb-sepolia");

        // 创建 CCIP 本地模拟器并使其持久化
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // 1. 在 Sepolia 上部署和配置代币
        (sepoliaToken, sepoliaPool, sepoliaNetworkDetails) = deployUtils
            .deployRebaseTokenAndPool(
                sepoliaFork,
                owner,
                ccipLocalSimulatorFork
            );

        // 部署金库合约在sepolia上
        vault = deployUtils.deployVault(
            sepoliaFork,
            owner,
            address(sepoliaToken)
        );

        // 2. 在 Arbitrum Sepolia 上部署和配置代币
        (
            arbSepoliaToken,
            arbSepoliaPool,
            arbSepoliaNetworkDetails
        ) = deployUtils.deployRebaseTokenAndPool(
            arbSepoliaFork,
            owner,
            ccipLocalSimulatorFork
        );

        // 使用 ConfigurePoolScript 配置 TokenPool
        configureTokenPool(
            sepoliaFork,
            address(sepoliaPool),
            arbSepoliaNetworkDetails.chainSelector,
            address(arbSepoliaPool),
            address(arbSepoliaToken)
        );
        configureTokenPool(
            arbSepoliaFork,
            address(arbSepoliaPool),
            sepoliaNetworkDetails.chainSelector,
            address(sepoliaPool),
            address(sepoliaToken)
        );
    }

    // 使用 ConfigurePoolScript 配置 TokenPool
    function configureTokenPool(
        uint256 fork,
        address localPool,
        uint64 remoteChainSelector,
        address remotePool,
        address remoteTokenAddress
    ) public {
        vm.selectFork(fork); // 选择指定的 fork
        ConfigurePoolScript configurePoolScript = new ConfigurePoolScript();
        configurePoolScript.run(
            owner, // 所有者地址
            localPool, // 本地 TokenPool 地址
            remoteChainSelector, // 远程链选择器
            remotePool, // 远程 TokenPool 地址
            remoteTokenAddress, // 远程 Token 地址
            false, // 是否启用出站速率限制器
            0, // 出站速率限制器容量
            0, // 出站速率限制器速率
            false, // 是否启用入站速率限制器
            0, // 入站速率限制器容量
            0 // 入站速率限制器速率
        );
    }

    // 桥接代币
    function bridgeTokens(
        uint256 amountToBridge,
        uint256 localFork,
        uint256 remoteFork,
        Register.NetworkDetails memory localNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails,
        RebaseToken localToken,
        RebaseToken remoteToken
    ) public {
        vm.selectFork(localFork); // 选择本地 fork

        // 定义 EVM2AnyMessage 结构体
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(localToken), // 代币地址
            amount: amountToBridge // 桥接金额
        });
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(user), // 接收者地址
            data: "", // 数据负载
            tokenAmounts: tokenAmounts, // 代币转移
            feeToken: localNetworkDetails.linkAddress, // 费用代币地址
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV2({
                    gasLimit: 1000000, // 气费限制
                    allowOutOfOrderExecution: false // 是否允许无序执行
                })
            )
        });

        // 获取费用
        uint256 fee = IRouterClient(localNetworkDetails.routerAddress).getFee(
            remoteNetworkDetails.chainSelector,
            message
        );

        // 请求 LINK 代币
        ccipLocalSimulatorFork.requestLinkFromFaucet(user, fee);

        // 批准费用代币
        vm.prank(user);
        IERC20(localNetworkDetails.linkAddress).approve(
            localNetworkDetails.routerAddress,
            fee
        );

        // 批准代币转移
        vm.prank(user);
        IERC20(address(localToken)).approve(
            localNetworkDetails.routerAddress,
            amountToBridge
        );

        // 记录本地代币余额
        uint256 localBalanceBefore = localToken.balanceOf(user);

        // 发送跨链消息
        vm.prank(user);
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(
            remoteNetworkDetails.chainSelector,
            message
        );

        // 记录本地代币余额变化
        uint256 localBalanceAfter = localToken.balanceOf(user);
        assertEq(localBalanceAfter, localBalanceBefore - amountToBridge);

        // 选择远程 fork
        vm.selectFork(remoteFork);
        // 模拟时间流逝
        vm.warp(block.timestamp + 20 minutes);

        // 记录远程代币余额
        uint256 remoteBalanceBefore = remoteToken.balanceOf(user);

        // 路由跨链消息
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork);

        // 记录远程代币余额变化
        uint256 remoteBalanceAfter = remoteToken.balanceOf(user);
        assertEq(remoteBalanceAfter, remoteBalanceBefore + amountToBridge);
    }

    // 测试桥接所有代币
    function testBridgeAllTokens() public {
        vm.selectFork(sepoliaFork); // 选择 Sepolia fork
        vm.deal(user, SEND_VALUE); // 给用户发送资金
        vm.prank(user);
        Vault(payable(address(vault))).deposit{value: SEND_VALUE}(); // 用户向钱包存入资金
        assertEq(sepoliaToken.balanceOf(user), SEND_VALUE); // 确认用户余额

        // 桥接代币从 Sepolia 到 Arbitrum Sepolia
        bridgeTokens(
            SEND_VALUE,
            sepoliaFork,
            arbSepoliaFork,
            sepoliaNetworkDetails,
            arbSepoliaNetworkDetails,
            sepoliaToken,
            arbSepoliaToken
        );

        // 选择 Arbitrum Sepolia fork
        vm.selectFork(arbSepoliaFork);
        // 模拟时间流逝
        vm.warp(block.timestamp + 20 minutes);

        // 桥接代币从 Arbitrum Sepolia 到 Sepolia
        bridgeTokens(
            arbSepoliaToken.balanceOf(user),
            arbSepoliaFork,
            sepoliaFork,
            arbSepoliaNetworkDetails,
            sepoliaNetworkDetails,
            arbSepoliaToken,
            sepoliaToken
        );
    }
}
