// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract RebaseTokenPool is TokenPool {
    /**
     * @notice 构造函数，初始化 RebaseTokenPool 合约。
     * @param _token 要管理的代币合约地址。
     * @param _allowlist 允许的地址列表。
     * @param _ramProxy RAM 代理合约地址。
     * @param _router 路由器合约地址。
     */
    constructor(
        IERC20 _token,
        address[] memory _allowlist,
        address _ramProxy,
        address _router
    ) TokenPool(_token, 18, _allowlist, _ramProxy, _router) {}

    /**
     * @notice 锁定或燃烧代币。
     * @param lockOrBurnIn 锁定或燃烧的输入参数。
     * @return lockOrBurnOut 锁定或燃烧的输出结果。
     * @dev 该函数用于锁定或燃烧代币，具体操作由 `_lockOrBurn` 完成。并将用户的利率传递到另一个链上
     */
    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    ) external returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut) {
        _validateLockOrBurn(lockOrBurnIn);
        uint256 userInterestRate = IRebaseToken(address(i_token))
            .getUserInterestRate(lockOrBurnIn.originalSender);
        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            destPoolData: abi.encode(userInterestRate)
        });
    }

    /**
     * @notice 释放或铸造代币。
     * @param releaseOrMintIn 释放或铸造的输入参数。
     * @return 释放或铸造的输出结果。
     */
    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory) {
        _validateReleaseOrMint(releaseOrMintIn);
        uint256 userInterestRate = abi.decode(
            releaseOrMintIn.sourcePoolData,
            (uint256)
        );
        IRebaseToken(address(i_token)).mint(
            releaseOrMintIn.receiver,
            releaseOrMintIn.amount,
            userInterestRate
        );
        return
            Pool.ReleaseOrMintOutV1({
                destinationAmount: releaseOrMintIn.amount
            });
    }
}
