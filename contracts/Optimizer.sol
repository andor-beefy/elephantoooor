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

    uint256 private totalSupply;
    uint256 private collateralBalance;

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

    function deposit(StableInfo _inputStables, address _bestYieldAddress) external nonReentrant {
        // TODO: accounting of user to token and amounts for how much interest should be given based on the amount of time staked
        // for now, we ignore calculating based on time, we just give user the average yield
        // checks - effects - interactions
        // user takes array of stable coins-amount from user
        // check the best rates via aave v3/v2, etc. (maybe we do this off chain and pass it in)
        // algorithm: highest interest is the stable we will swap to
        // based on rates we either swap tokens or not at curve or uniswap v3 (this can be done off chain possibly)
        if (_inputStables.tokenAddress ==  _bestYieldAddress) {
            // deposit tokens into aave for lending
            _depositToAave(_bestYieldAddress, _inputStables.amount)
            // mint StableYieldToken to user of input amount 
            _handleMint(address msg.sender, uint256 _inputStables.amount)
        } else {
            // swap tokens to deposit_bestYieldAddress and then deposits these tokens into aave for lending
            curveResultAmount = swapInCurve(_inputStables.tokenAddress, _bestYieldAddress, _inputStables.amount)
            // deposit tokens into aave for lending
            _depositToAave(_bestYieldAddress, curveResultAmount)
            // mint StableYieldToken to user equal to amount of _bestYieldAddress tokens we got from curve
            _handleMint(address msg.sender, uint256 curveResultAmount)


        }
        // mint StableYieldToken to user of amount 
        _handleMint(address msg.sender, uint256 _inputStables.amount)
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

    function _handleMint(address _account, uint256 amount) internal {
        totalSupply = totalSupply + amount
        collateralBalance = collateralBalance + amount
        assert(totalSupply <= collateralBalance);
         _mint(_account, _amount);
    }

    function _calculateWithdrawalFee(uint256 _withdrawalAmount) internal view returns (uint256) {
        return (_withdrawalAmount * managementFee) / ONE_HUNDRED_PERCENT;
    }


    function _authorizeUpgrade(address) internal override {}

    function getTotalSupply() public returns (unint256) {
        return totalSupply
    }

    function getcollateralBalance() public returns (unint256) {
        return collateralBalance
    }

    function _depositToAave(address _inputAddress, uint256 amount) internal {

        // Retrieve LendingPool address
        // this is for Ropsten!
        LendingPoolAddressesProvider provider = LendingPoolAddressesProvider(address(0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728)); // mainnet address, for other addresses: https://docs.aave.com/developers/developing-on-aave/deployed-contract-instances
        LendingPool lendingPool = LendingPool(provider.getLendingPool());

        // Input variables
        address daiAddress = address(_inputAddress);
        uint256 amount = amount * 1e18;
        uint16 referral = 0;

        // Approve LendingPool contract to move your DAI
        IERC20(daiAddress).approve(provider.getLendingPoolCore(), amount);

        // Deposit 1000 DAI
        lendingPool.deposit(daiAddress, amount, referral);
    }

    function swapInCurve(address _from, address _to, uint256 amount) internal returns (uint256) {

    }
}
