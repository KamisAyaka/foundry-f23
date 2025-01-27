# Decentralized Stable Coin (DSC) Project

## 项目概述

本项目实现了一个去中心化的稳定币（Decentralized Stable Coin, DSC），该稳定币通过抵押 wETH 和 wBTC 来铸造，并保持与美元的 1:1 挂钩。项目的智能合约使用 Solidity 编写，测试框架基于 Foundry。

## 目录结构

```
foundry-defi-stablecoin-f23/
├── README.md
├── script/
│   ├── DeployDSC.s.sol
│   └── HelperConfig.s.sol
├── src/
│   ├── DecentralizedStableCoin.sol
│   ├── DSCEngine.sol
│   └── libraries/
│       └── OracleLib.sol
├── test/
│   ├── fuzz/
│   │   ├── Handler.t.sol
│   │   └── InvariantsTest.t.sol
│   └── unit/
│       └── DSCEngineTest.t.sol
└── ...
```

## 核心组件

### 1. DecentralizedStableCoin.sol

- **描述**: 实现 ERC20 稳定币合约，允许铸造和销毁 DSC。
- **功能**:
  - `mint`: 铸造 DSC。
  - `burn`: 销毁 DSC。
- **错误处理**:
  - `DecentralizedStableCoin__MustBeMoreThanZero`: 数量必须大于零。
  - `DecentralizedStableCoin__BurnAmountExceedsBalance`: 销毁数量超过余额。
  - `DecentralizedStableCoin__NotZeroAddress`: 地址不能为零地址。

### 2. DSCEngine.sol

- **描述**: 核心逻辑合约，管理抵押品和 DSC 的铸造、赎回、清算等操作。
- **功能**:
  - `depositCollateral`: 存入抵押品。
  - `mintDsc`: 铸造 DSC。
  - `redeemCollateral`: 赎回抵押品。
  - `liquidate`: 清算违约用户的抵押品。
  - `getUsdValue`: 获取抵押品的 USD 价值。
  - `getHealthFactor`: 获取用户的健康因子。
- **错误处理**:
  - `DSCEngine__NeedsMoreThanZero`: 数量必须大于零。
  - `DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength`: 抵押品地址和价格馈送地址长度不匹配。
  - `DSCEngine__TokenNotAllowed`: 不允许的抵押品。
  - `DSCEngine__TransferFailed`: 转账失败。
  - `DSCEngine__BreaksHealthFactor`: 健康因子低于最低要求。
  - `DSCEngine__MintFailed`: 铸造失败。
  - `DSCEngine__HealthFactorOk`: 健康因子正常。
  - `DSCEngine__HealthFactorNotImproved`: 清算后健康因子未改善。

### 3. OracleLib.sol

- **描述**: 提供 Chainlink 价格馈送的检查功能，确保价格数据不过期。
- **功能**:
  - `stableCheckLatestRoundData`: 检查最新的价格数据是否过期。

### 4. DeployDSC.s.sol

- **描述**: 部署脚本，用于部署 DSC 和 DSCEngine 合约。
- **功能**:
  - `run`: 部署 DSC 和 DSCEngine，并初始化相关配置。

### 5. HelperConfig.s.sol

- **描述**: 辅助配置脚本，提供不同网络的配置信息。
- **功能**:
  - `getSepoliaEthConfig`: 获取 Sepolia 测试网配置。
  - `getOrCreateAnvilEthConfig`: 获取或创建 Anvil 测试网配置。

## 测试

### 单元测试

#### 文件: `test/unit/DSCEngineTest.t.sol`

#### 概述

`DSCEngineTest.t.sol` 是一个单元测试文件，用于验证 `DSCEngine` 合约的功能。该合约是稳定币系统的核心逻辑合约，负责管理抵押品和 DSC 的铸造、赎回、清算等操作。测试文件通过模拟各种场景来确保合约的各个功能模块按预期工作。

#### 主要测试内容

- **构造函数测试**:
  - `testRevertIfTokenLengthDoesNotMatchPriceFeedsLength`: 测试当抵押品地址数组和价格馈送地址数组长度不匹配时是否会 revert。
- **价格计算测试**:

  - `testGetUsdValue`: 测试将抵押品金额转换为 USD 价值的功能是否正确。
  - `testGetTokenAmountFromUsd`: 测试将 USD 金额转换为抵押品数量的功能是否正确。

- **存入抵押品测试**:

  - `testRevertsIfTransferFromFails`: 测试当转账失败时是否会 revert。
  - `testRevertIfCollateralZero`: 测试当抵押品数量为零时是否会 revert。
  - `testRevertWithUnapprovedCollateral`: 测试使用未批准的抵押品时是否会 revert。
  - `testCanDepositCollateralWithoutMinting`: 测试用户可以存入抵押品但不铸造 DSC。
  - `testCanDepositCollateralAndGetAccountInfo`: 测试存入抵押品后可以获取正确的账户信息。

- **存入抵押品并铸造 DSC 测试**:

  - `testRevertsIfMintedDscBreaksHealthFactor`: 测试当铸造的 DSC 数量超过健康因子允许范围时是否会 revert。
  - `testCanMintWithDepositedCollateral`: 测试用户可以存入抵押品并铸造 DSC。

- **铸造 DSC 测试**:

  - `testRevertsIfMintFails`: 测试当铸造失败时是否会 revert。
  - `testRevertsIfMintAmountIsZero`: 测试当铸造数量为零时是否会 revert。
  - `testRevertsIfMintAmountBreaksHealthFactor`: 测试当铸造数量超过健康因子允许范围时是否会 revert。
  - `testCanMintDsc`: 测试用户可以铸造 DSC。

- **销毁 DSC 测试**:

  - `testRevertsIfBurnAmountIsZero`: 测试当销毁数量为零时是否会 revert。
  - `testCantBurnMoreThanUserHas`: 测试用户不能销毁超过自己拥有的 DSC。
  - `testCanBurnDsc`: 测试用户可以销毁 DSC。

- **赎回抵押品测试**:

  - `testRevertsIfTransferFails`: 测试当转账失败时是否会 revert。
  - `testRevertsIfRedeemAmountIsZero`: 测试当赎回数量为零时是否会 revert。
  - `testCanRedeemCollateral`: 测试用户可以赎回抵押品。
  - `testEmitCollateralRedeemedWithCorrectArgs`: 测试赎回抵押品时会发出正确的事件。

- **赎回抵押品以偿还 DSC 测试**:

  - `testMustRedeemMoreThanZero`: 测试赎回数量必须大于零。
  - `testCanRedeemDepositedCollateral`: 测试用户可以赎回抵押品以偿还 DSC。

- **健康因子测试**:

  - `testProperlyReportsHealthFactor`: 测试健康因子计算是否正确。
  - `testHealthFactorCanGoBelowOne`: 测试健康因子可以低于 1。

- **清算测试**:

  - `testMustImproveHealthFactorOnLiquidation`: 测试清算后用户的健康因子必须有所改善。
  - `testCantLiquidateGoodHealthFactor`: 测试不能清算健康因子正常的用户。
  - `testLiquidationPayoutIsCorrect`: 测试清算后的赔付是否正确。
  - `testUserStillHasSomeEthAfterLiquidation`: 测试清算后用户仍然保留部分抵押品。
  - `testLiquidatorTakesOnUsersDebt`: 测试清算者承担了用户的债务。
  - `testUserHasNoMoreDebt`: 测试清算后用户不再有债务。

- **视图与纯函数测试**:
  - `testGetCollateralTokenPriceFeed`: 测试获取抵押品的价格馈送地址。
  - `testGetCollateralTokens`: 测试获取所有抵押品代币。
  - `testGetMinHealthFactor`: 测试获取最小健康因子。
  - `testGetLiquidationThreshold`: 测试获取清算阈值。
  - `testGetAccountCollateralValueFromInformation`: 测试从账户信息中获取抵押品价值。
  - `testGetCollateralBalanceOfUser`: 测试获取用户的抵押品余额。
  - `testGetAccountCollateralValue`: 测试获取用户的抵押品总价值。
  - `testGetDsc`: 测试获取 DSC 地址。
  - `testLiquidationPrecision`: 测试获取清算精度。

### 模糊测试

#### 文件: `test/fuzz/Handler.t.sol`, `test/fuzz/InvariantsTest.t.sol`

#### 概述

模糊测试（fuzz testing）是一种通过生成大量随机输入并在智能合约上执行操作来发现潜在问题的测试方法。这些测试文件用于确保合约在极端情况下仍能正常运行。

#### 文件: `test/fuzz/Handler.t.sol`

##### 概述

`Handler.t.sol` 是一个模糊测试处理程序，用于生成随机输入并在智能合约上执行操作。它主要用于不变性测试，确保在大量随机操作下合约的行为仍然符合预期。

##### 主要功能

- **初始化**:

  - 构造函数中初始化 `DSCEngine` 和 `DecentralizedStableCoin` 实例，并设置抵押品代币和价格馈送。

- **铸造 DSC**:

  - `mintDsc`: 根据用户的抵押品价值，随机生成一个合法的 DSC 铸造数量并执行铸造操作。

- **存入抵押品**:

  - `depositCollateral`: 随机选择一种抵押品代币，随机生成一个合法的抵押品数量并存入合约。

- **赎回抵押品**:

  - `redeemCollateral`: 随机选择一种抵押品代币，随机生成一个合法的赎回数量并执行赎回操作。

- **辅助函数**:
  - `_getCollateralFromSeed`: 根据种子值选择 wETH 或 wBTC 作为抵押品代币。

#### 文件: `test/fuzz/InvariantsTest.t.sol`

##### 概述

`InvariantsTest.t.sol` 是一个不变性测试文件，用于验证 `DSCEngine` 合约在大量随机操作后是否仍然保持某些关键属性不变。不变性测试是一种强大的工具，可以在模糊测试中确保合约的状态始终符合预期。

##### 主要测试内容

- **协议总价值不低于 DSC 总供应量**:

  - `invariant_protocolMustHaveMoreValueThanTotalSupply`: 确保协议中的抵押品总价值（wETH 和 wBTC 的 USD 价值之和）不低于 DSC 的总供应量。

- **getter 函数不会 revert**:
  - `invariant_gettersShouldNotRevert`: 确保所有 getter 函数（如 `getCollateralTokens`, `getDsc`, `getLiquidationThreshold` 等）不会 revert。

这些测试确保了即使在大量随机操作下，合约的关键属性仍然保持不变，从而提高了系统的可靠性和安全性。

## 如何运行

### 安装依赖

```bash
forge install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
forge test
```

### 部署合约

```bash
forge script script/DeployDSC.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## 参考资料

- [Solidity 文档](https://docs.soliditylang.org/)
- [Foundry 文档](https://book.getfoundry.sh/)
- [Chainlink 文档](https://docs.chain.link/)

---
