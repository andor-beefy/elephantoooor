// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IStableYieldCoin} from "./interfaces/IStableYieldCoin.sol";

contract Optimizer is Initializable, Ownable, ReentrancyGuard, UUPSUpgradeable {

    uint256 constant ONE_HUNDRED_PERCENT = 10000;

    // structs
    struct StableInfo {
        address tokenAddress;
        uint256 amount;
    }

    // state
    IStableYieldCoin public token;
    uint256 public managementFee;

    function initialize(IStableYieldCoin _token) external initializer {
        token = _token;
    }

    // events

    // custom errors

    // modifiers

    // functions
    
    // aave v3

    function setManagementFee(uint256 _managementFee) public onlyOwner {
        managementFee = _managementFee;
    }

    function deposit() external nonReentrant {
        // TODO: accounting of user to token and amounts for how much interest should be given based on the amount of time staked
        // for now, we ignore calculating based on time, we just give user the average yield
        // checks - effects - interactions
        // user takes array of stable coins-amount from user
        // check the best rates via aave v3/v2, etc. (maybe we do this off chain and pass it in)
        // algorithm: highest interest is the stable we will swap to
        // based on rates we either swap tokens or not at curve or uniswap v3 (this can be done off chain possibly)
        // deposit tokens into aave for lending
        // mint StableYieldToken to user of amount 
        // maybe make this function generic so we can plug any protocol (later)
    }

    function redeem() external {
        // check APYs of AAVE pools, check enough liquidity for amount in that pool (if not, withdraw as much as possible from pool) - off-chain prolly
        // offchain: input is token + amount (For now just one token, one amount), output is what to withdraw and swap from aave (by lowest APY)
        // update user info in mapping
        // burn user's StableYield tokens 
        // withdraw from aave and swap to underlying, if necessary, do swaps on curve/uniswap v3 (uni vs. curve done off-chain)
    }

    function rebalance() external onlyOwner {
        // check for minimum time before able to rebalance
        // checks the best yield again on aave v3 off-chain and if funds are not allocated optimally, move funds
        // swap current stables to new stables to optimize for yield
        // can be done via aave or maybe curve/univ3 then redeposit into aave
    }

    // view functions

    function getRebalanceAmounts() external {}

    function _handleMint() internal {
        // do mint of StableYield token
        // assert(totalSupply of StableYield <= collateralBalance);
    }

    function _calculateWithdrawalFee(uint256 _withdrawalAmount) internal view returns (uint256) {
        return (_withdrawalAmount * managementFee) / ONE_HUNDRED_PERCENT;
    }


    function _authorizeUpgrade(address) internal override {}
}
