// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UniswapV3Swap} from "./UniswapV3Swap.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


contract Optimizer is Initializable, Ownable, ReentrancyGuard, UUPSUpgradeable, ERC20("Stable Yield Coin", "SYC") {
    uint256 constant ONE_HUNDRED_PERCENT = 10000;

    // structs
    struct StableInfo {
        address tokenAddress;
        uint256 amount;
    }
    struct LendingData {
        uint256 fromIndex;
        uint256 amountAccruedSince;
    }

    // state
    UniswapV3Swap private uniswapSwap;
    IPoolAddressesProvider public aavePoolAddressesProvider;
    uint256 public managementFee;
    uint256 private collateralBalance;
    uint256 private amountOutMinimumModifier;
    address uniswapRouterAddress;
    mapping(address => LendingData) public userToDataMap;

    function initialize(
        IPoolAddressesProvider _aavePoolAddressesProvider, 
        uint256 _managementFee,
        uint256 _amountOutMinimumModifier,
        address _uniswapRouterAddress
        )
        external
        initializer
    {
        aavePoolAddressesProvider = _aavePoolAddressesProvider;
        managementFee = _managementFee;
        amountOutMinimumModifier = _amountOutMinimumModifier;
        uniswapRouterAddress = _uniswapRouterAddress;

        ISwapRouter swapRouter = ISwapRouter(_uniswapRouterAddress);

        uniswapSwap = new UniswapV3Swap(swapRouter); // 0xE592427A0AEce92De3Edee1F18E0157C05861564
    }

    // events

    // custom errors

    // modifiers

    // functions

    // aave v3

    function setManagementFee(uint256 _managementFee) public onlyOwner {
        managementFee = _managementFee;
    }

    function deposit(StableInfo calldata _inputStables, address _bestYieldAddress) external nonReentrant {
        // TODO: accounting of user to token and amounts for how much interest should be given based on the amount of time staked
        // for now, we ignore calculating based on time, we just give user the average yield
        // checks - effects - interactions
        // user takes array of stable coins-amount from user
        // check the best rates via aave v3/v2, etc. (maybe we do this off chain and pass it in)
        // algorithm: highest interest is the stable we will swap to
        // based on rates we either swap tokens or not at curve or uniswap v3 (this can be done off chain possibly)
        if (_inputStables.tokenAddress ==  _bestYieldAddress) {
            // deposit tokens into aave for lending
            _depositToAave(_bestYieldAddress, _inputStables.amount);
            // mint StableYieldToken to user of input amount 
            _handleMint(msg.sender, _inputStables.amount);
        } else {
            // swap tokens to deposit_bestYieldAddress and then deposits these tokens into aave for lending
            uint256 curveResultAmount = swapInUniswapV3(_inputStables.tokenAddress, _bestYieldAddress, _inputStables.amount);
            // deposit tokens into aave for lending
            _depositToAave(_bestYieldAddress, curveResultAmount);
            // mint StableYieldToken to user equal to amount of _bestYieldAddress tokens we got from curve
            _handleMint(msg.sender, curveResultAmount);


        }
        // mint StableYieldToken to user of amount 
        _handleMint(msg.sender, _inputStables.amount);

        // maybe make this function generic so we can plug any protocol (later)
    }

    /**
     * @notice User burns their Stable Yield Coin to redeem desired token.
     * @dev Take as much liquidity from lowest APY pools.
     */
    function redeem(
        StableInfo calldata _desiredStableData,
        StableInfo[] calldata _withdrawalData
    ) external {
        IPool pool = IPool(aavePoolAddressesProvider.getPool());
        _burn(msg.sender, _desiredStableData.amount);
        for (uint8 i = 0; i < _withdrawalData.length; i++) {
            pool.withdraw(
                _withdrawalData[i].tokenAddress,
                _withdrawalData[i].amount,
                address(this)
            );
            // approve uniswap permissions
            // swap to desired stable in withdrawal data amounts
        }

        // send desired token to user
        //
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

    function _handleMint(address _account, uint256 _amount) internal {
        _mint(_account, _amount);
        collateralBalance = collateralBalance + _amount;
        assert(totalSupply() <= collateralBalance);
    }

    function _calculateWithdrawalFee(uint256 _withdrawalAmount)
        internal
        view
        returns (uint256)
    {
        return (_withdrawalAmount * managementFee) / ONE_HUNDRED_PERCENT;
    }


    function getCollateralBalance() public view returns (uint256) {
        return collateralBalance;
    }

    function getAmountOutMinimumModifier() public view returns (uint256) {
        return amountOutMinimumModifier;
    }

    function _depositToAave(address _inputAddress, uint256 _amount) internal {

        // Retrieve LendingPool address
        // this is for Ropsten!
        IPool pool = IPool(aavePoolAddressesProvider.getPool());

        // Input variables
        address tokenAddress = address(_inputAddress);
        uint16 referral = 0;

        // Approve LendingPool contract to move the input tokens
        IERC20(tokenAddress).approve(address(pool), _amount);

        // Deposit the input tokens
        pool.supply(tokenAddress, _amount, address(this), referral);
    }

    function swapInUniswapV3(address _from, address _to, uint256 _amount) internal returns (uint256) {
        uint minimalAmount = (_amount * 100) / amountOutMinimumModifier;
        return uniswapSwap.swapExactInputSingle(_amount, _from, _to, minimalAmount);
    }

    function getSwapRouterAddress() public view returns (address) {
        return uniswapRouterAddress;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

}
