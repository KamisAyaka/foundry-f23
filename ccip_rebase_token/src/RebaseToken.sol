// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Firefly
 * @notice This is a cross-chain rebase token that incentivates users to deposit into a vault and gain interest in rewards.
 * @notice This interest rate in the smart contract can only decrease.
 * @notice Each user will have their own interest rate that is the global interest rate at the time they deposit.
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
     * @notice Sets the interest rate for the token.
     * @param _newInterestRate The new interest rate to set.
     * @dev The interest rate can only decrease.
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
     * @notice Get the principle balance of a user. This is the number of tokens that have currently been minted to the user, not including any interest accrued.
     * @param _user The address of the user to check the principle balance for.
     * @return The principle balance of the user.
     */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Mints tokens to a user when they deposit into a vault.
     * @param _to     The address of the user to mint tokens to.
     * @param _amount  The amount of tokens to mint.
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
     * @notice Burn the user tokens when they withdraw from a vault.
     * @param _from  The address of the user to burn tokens from.
     * @param _amount  The amount of tokens to burn.
     */
    function burn(
        address _from,
        uint256 _amount
    ) public onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice Calculates the balance of a user including accrued interest.
     * principle balance + accrued interest
     * @param _user  The address of the user to calculate the balance for.
     * @return The balance of the user including accrued interest.
     */
    function balanceOf(address _user) public view override returns (uint256) {
        return
            (super.balanceOf(_user) *
                _calculateUserAccumulatedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @param _recipient The address of the recipient.
     * @param _amount  The amount of tokens to transfer.
     * @return True if the transfer was successful, false otherwise.
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
     * @notice Transfer tokens from one address to another.
     * @param _sender  The user to transfer the tokens from.
     * @param _recipient The user to transfer the tokens to.
     * @param _amount The amount of tokens to transfer.
     * @return True if the transfer was successful, false otherwise.
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
     * @notice Calculates the accrued interest for a user and mints the tokens to them.
     * @param _user The address of the user to calculate the accrued interest for.
     */
    function _mintAccruedInterest(address _user) private {
        // find their current balance of rebase tokens that have been minted to the user -> principal
        uint256 previousPrincipalBalance = super.balanceOf(_user);
        // calculate their current balance of rebase tokens -> balanceof
        uint256 currentBalance = balanceOf(_user);
        // calculate the number of tokens that need to be minted to the user -> accruedInterest
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;
        // mint the accruedInterest to the user
        s_userlastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice Get the interest rate of the token currently set for the contract.
     * @return The interest rate of the token.
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice Get the interest rate for a user.
     * @param _user The address of the user.
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
