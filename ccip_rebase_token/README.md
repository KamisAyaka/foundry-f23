## Cross-chain Rebase Token 项目文档

### 项目概述

本项目实现了一种跨链可调整的 Rebase 代币（RebaseToken），用户可以将 ETH 存入 Vault 合约中以获得 RebaseToken，并根据存款时间获得利息奖励。此外，项目支持在不同区块链网络之间桥接这些代币。

### 文件结构

- **src/**: 包含所有智能合约源代码。

  - `RebaseToken.sol`: 实现了 RebaseToken 的核心逻辑，包括铸币、销毁、计算用户余额等功能。
  - `RebaseTokenPool.sol`: 继承自 CCIP 的`TokenPool`，用于处理跨链转账时锁定或铸造代币的操作。
  - `Vault.sol`: 用户可以将 ETH 存入此合约并获得相应的 RebaseToken；也可以赎回 RebaseToken 以取回 ETH。
  - `interfaces/IRebaseToken.sol`: 定义了 RebaseToken 接口，供其他合约调用。

- **test/**: 测试文件夹，包含对各个合约功能进行单元测试的脚本。

  - `CrossChain.t.sol`: 测试跨链桥接功能。
  - `RebaseToken.t.sol`: 测试 RebaseToken 的基本功能如存款、取款、转账等。

- **script/**: 部署和配置相关脚本。

  - `Deployer.s.sol`: 提供了部署 RebaseToken 及其对应的 RebaseTokenPool 的方法。
  - `SetPermissions.s.sol`: 设置权限给特定地址，使其能够执行铸币/销毁操作。
  - `VaultDeployer.s.sol`: 部署 Vault 合约并与 RebaseToken 关联。
  - `BridgeToken.s.sol`: 桥接代币到另一个链上的脚本。
  - `ConfigurePool.s.sol`: 配置 TokenPool 参数的脚本。
  - `DeployUtils.s.sol`: 综合部署 RebaseToken，Vault 和设置权限。

- **bridgeToZksync.sh**: 用于将代币桥接到 ZkSync 网络的脚本。

### 使用说明

#### 环境准备

确保已安装以下工具：

- [Foundry](https://book.getfoundry.sh/getting-started/installation)：用于编译和测试 Solidity 合约。
- [Forge](https://github.com/foundry-rs/foundry)：Foundry 提供的命令行工具集。

#### 编译合约

```bash
forge build
```

#### 运行测试

```bash
forge test
```

#### 部署合约

1. 修改`script/Deployer.s.sol`中的参数以适应目标网络。
2. 使用以下命令部署合约：

```bash
forge script script/Deployer.s.sol:TokenAndPoolDeployer --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

3. 同样地，可以使用类似的方式运行其他脚本来完成权限设置、池子配置以及代币桥接等任务。

#### 桥接代币到 ZkSync

`bridgeToZksync.sh` 脚本用于将代币桥接到 ZkSync 网络。以下是脚本内容：

```bash
#!/bin/bash

# Load environment variables
env

# Define variables
SENDER_PRIVATE_KEY=$SENDER_PRIVATE_KEY
RECEIVER_ADDRESS=$RECEIVER_ADDRESS
DESTINATION_CHAIN_SELECTOR=$DESTINATION_CHAIN_SELECTOR
TOKEN_TO_SEND_ADDRESS=$TOKEN_TO_SEND_ADDRESS
AMOUNT_TO_SEND=$AMOUNT_TO_SEND
LINK_TOKEN_ADDRESS=$LINK_TOKEN_ADDRESS
ROUTER_ADDRESS=$ROUTER_ADDRESS

# Execute the bridge operation
forge script script/BridgeToken.s.sol:BridgeTokenScript \
    --rpc-url $RPC_URL \
    --private-key $SENDER_PRIVATE_KEY \
    --broadcast \
    --sig "run(address,uint64,address,uint256,address,address)" \
    $RECEIVER_ADDRESS \
    $DESTINATION_CHAIN_SELECTOR \
    $TOKEN_TO_SEND_ADDRESS \
    $AMOUNT_TO_SEND \
    $LINK_TOKEN_ADDRESS \
    $ROUTER_ADDRESS
```

**使用方法：**

1. 设置环境变量，例如：

```bash
export SENDER_PRIVATE_KEY=your_private_key
export RECEIVER_ADDRESS=receiver_address
export DESTINATION_CHAIN_SELECTOR=destination_chain_selector
export TOKEN_TO_SEND_ADDRESS=token_to_send_address
export AMOUNT_TO_SEND=amount_to_send
export LINK_TOKEN_ADDRESS=link_token_address
export ROUTER_ADDRESS=router_address
export RPC_URL=your_rpc_url
```

2. 运行脚本：

```bash
./bridgeToZksync.sh
```

### 注意事项

- 本项目依赖于 CCIP 库来实现跨链通信，请确保正确引入相关依赖。
- 在实际应用前，请务必仔细审查所有代码，并考虑安全性和性能问题。
- 由于涉及到多个链之间的交互，建议先在一个测试环境中充分验证后再上线主网。

希望这份 README 能帮助你更好地理解和使用本项目！如果有任何疑问或建议，请随时联系开发者团队。
