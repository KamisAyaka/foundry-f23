// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Firefly
 * @notice 这是一个跨链复利代币，激励用户将资金存入金库并获得奖励利息。
 * @notice 智能合约中的利率只能降低。
 * @notice 每个地址将拥有他们在存入时的全局利率。
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InterestRateCanOnlyDecreased(
        uint256 _oldInterestRate,
        uint256 _newInterestRate
    );

    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 public constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userlastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, account);
    }

    /**
     * @notice 设置代币的利率。
     * @param _newInterestRate 要设置的新利率。
     * @dev 利率只能降低。
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecreased(
                s_interestRate,
                _newInterestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice 获取用户的本金余额。这是目前已被铸造给用户的代币数量，不包括任何累计的利息。
     * @param _user 要检查本金余额的用户地址。
     * @return 用户的本金余额。
     */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice 当用户将资金存入金库时，向用户铸造代币。
     * @param _to 要铸造代币的用户地址。
     * @param _amount 要铸造的代币数量。
     */
    function mint(
        address _to,
        uint256 _amount,
        uint256 _userInterestRate
    ) public onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice 当用户从金库中取出资金时，燃烧用户的代币。
     * @param _from 要燃烧代币的用户地址。
     * @param _amount 要燃烧的代币数量。
     */
    function burn(
        address _from,
        uint256 _amount
    ) public onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice 计算用户的余额，包括累计的利息。
     * 本金余额 + 累计利息
     * @param _user 要计算余额的用户地址。
     * @return 包括累计利息在内的用户余额。
     */
    function balanceOf(address _user) public view override returns (uint256) {
        return
            (super.balanceOf(_user) *
                _calculateUserAccumulatedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    /**
     * @notice 从一个地址向另一个地址转账。
     * @param _recipient 接收者的地址。
     * @param _amount 要转账的代币数量。
     * @return 如果转账成功则返回true，否则返回false。
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice 从一个地址向另一个地址转账。
     * @param _sender 要转账的代币来源地址。
     * @param _recipient 要转账的代币接收地址。
     * @param _amount 要转账的代币数量。
     * @return 如果转账成功则返回true，否则返回false。
     * 可以在代码部署早期存入少量token来获取高的利率，之后再将大量的token存入该地址获得同样的利率而不会随着时间衰减。
     * 还可以创建多个高利率的账户，通过将多个账户的token存入该地址来获得更高的利率。
     * 这是代码本身设计的时候产生的缺陷问题。
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * 计算用户自上次更新以来累计的利息。
     *
     * 该函数通过计算从上次更新到当前时间的利息，来确定用户在这段时间内应得的利息。
     * 它主要用于内部调用，以处理用户的利息计算。
     *
     * @param _user 用户地址，用于识别特定用户的利息和上次更新时间。
     * @return 返回用户自上次更新以来的线性利息值。
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256) {
        // 计算当前时间与用户上次更新时间的差值
        uint256 timeSinceLastUpdate = block.timestamp -
            s_userlastUpdatedTimestamp[_user];
        // 根据用户利率和时间差计算线性利息，并加上精度因子以确保计算精度
        uint256 linearInterest = PRECISION_FACTOR +
            s_userInterestRate[_user] *
            timeSinceLastUpdate;
        // 返回计算出的线性利息值
        return linearInterest;
    }

    /**
     * @notice 计算用户的累计利息并向用户铸造代币。
     * @param _user 要计算累计利息的用户地址。
     */
    function _mintAccruedInterest(address _user) private {
        // 找到目前已被铸造给用户的复利代币余额 -> 本金
        uint256 previousPrincipalBalance = super.balanceOf(_user);
        // 计算用户的当前复利代币余额 -> balanceof
        uint256 currentBalance = balanceOf(_user);
        // 计算需要向用户铸造的代币数量 -> 累计利息
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;
        // 向用户铸造累计利息
        s_userlastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice 获取合约中当前设置的代币利率。
     * @return 代币的利率。
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice 获取用户的利率。
     * @param _user 用户地址。
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
