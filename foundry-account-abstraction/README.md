## README

### 项目概述

本项目实现了基于以太坊和 zkSync 的账户抽象（Account Abstraction）合约，包括最小化实现的智能合约账户（MinimalAccount 和 ZkMinimalAccount），以及相关的测试和部署脚本。通过这些合约，用户可以创建自定义的智能合约账户，并使用签名验证机制来执行交易。

### 文件结构

- **README.md**: 项目的说明文档。
- **test/zkSync/ZkMinimalAccountTest.t.sol**: zkSync 环境下的 ZkMinimalAccount 合约的测试文件。
- **script/HelperConfig.s.sol**: 提供网络配置信息的辅助脚本。
- **script/DeployMinimal.s.sol**: 部署 MinimalAccount 合约的脚本。
- **src/ethereum/MinimalAccount.sol**: 以太坊环境下的 MinimalAccount 合约。
- **src/zksync/ZKMinimalAccount.sol**: zkSync 环境下的 ZkMinimalAccount 合约。
- **test/ethereum/MinimalAccountTest.t.sol**: 以太坊环境下的 MinimalAccount 合约的测试文件。
- **script/SendPackedUserOp.s.sol**: 生成并发送打包的用户操作（UserOperation）的脚本。

### 合约介绍

#### MinimalAccount.sol

这是一个简化版的智能合约账户，实现了基本的账户抽象功能。它允许所有者执行交易，并且可以通过签名验证机制确保交易的有效性。

- **主要功能**:
  - `execute`: 执行指定的目标地址、值和数据的交易。
  - `validateUserOp`: 验证用户操作的有效性，包括签名验证和预支付资金。

#### ZKMinimalAccount.sol

这是专门为 zkSync 环境设计的智能合约账户，继承了 IAccount 接口，并实现了特定于 zkSync 的交易验证和执行逻辑。

- **主要功能**:
  - `validateTransaction`: 验证交易的有效性，包括更新 nonce 和检查余额。
  - `executeTransaction`: 执行已验证的交易。
  - `payForTransaction`: 支付交易费用给 bootloader。

### 测试用例

#### MinimalAccountTest.t.sol

该文件包含了对 MinimalAccount 合约的功能测试，确保其在以太坊环境下的正确性和安全性。

- **主要测试点**:
  - `testOwnerCanExecuteCommands`: 测试所有者能否成功执行命令。
  - `testNonOwnerCanNotExecuteCommands`: 测试非所有者无法执行命令。
  - `testRecoverSignedOp`: 测试签名恢复功能。
  - `testValidationOfUserOps`: 测试用户操作验证功能。
  - `testEntryPointCanExecuteCommands`: 测试入口点能否执行命令。

#### ZkMinimalAccountTest.t.sol

该文件包含了对 ZkMinimalAccount 合约的功能测试，确保其在 zkSync 环境下的正确性和安全性。

- **主要测试点**:
  - `testZkOwnerCanExecuteCommands`: 测试所有者能否成功执行命令。
  - `testZkValidateTransaction`: 测试交易验证功能。

### 部署脚本

#### DeployMinimal.s.sol

此脚本用于部署 MinimalAccount 合约，并设置初始配置。

- **主要功能**:
  - `deployMinimalAccount`: 部署 MinimalAccount 合约，并将其所有权转移给指定账户。

#### SendPackedUserOp.s.sol

此脚本用于生成并发送打包的用户操作（UserOperation），适用于与账户抽象相关的交易。

- **主要功能**:
  - `generateSignedUserOperation`: 生成并签名用户操作。
  - `run`: 发送用户操作到入口点合约。

### 使用方法

1. **安装依赖**:
   确保你已经安装了 Foundry 工具链，并且已经克隆了本项目仓库。

2. **编译合约**:

   ```bash
   forge build
   ```

3. **运行测试**:

   ```bash
   forge test
   ```

4. **部署合约**:
   使用`DeployMinimal.s.sol`脚本部署 MinimalAccount 合约：

   ```bash
   forge script script/DeployMinimal.s.sol:DeployMinimal --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
   ```

5. **发送用户操作**:
   使用`SendPackedUserOp.s.sol`脚本发送用户操作：
   ```bash
   forge script script/SendPackedUserOp.s.sol:SendPackedUserOp --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
   ```

### 注意事项

- 在本地开发环境中，请确保使用正确的网络配置（如 Anvil 或 Hardhat 节点）。
- 部署和发送用户操作时，请替换`<RPC_URL>`和`<PRIVATE_KEY>`为实际的 RPC URL 和私钥。
