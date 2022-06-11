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
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Optimizer is
    Initializable,
    Ownable,
    ReentrancyGuard,
    UUPSUpgradeable,
    ERC20("Stable Yield Coin", "SYC")
{
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
    address public uniswapRouterAddress;
    uint256 public managementFee;
    uint256 private collateralBalance;
    uint256 private amountOutMinimumModifier;
    mapping(address => LendingData) public userToDataMap;

    function initialize(
        IPoolAddressesProvider _aavePoolAddressesProvider,
        uint256 _managementFee,
        uint256 _amountOutMinimumModifier,
        address _uniswapRouterAddress
    ) external initializer {
        aavePoolAddressesProvider = _aavePoolAddressesProvider;
        managementFee = _managementFee;
        amountOutMinimumModifier = _amountOutMinimumModifier;
        uniswapRouterAddress = _uniswapRouterAddress;

        ISwapRouter swapRouter = ISwapRouter(_uniswapRouterAddress);

        uniswapSwap = new UniswapV3Swap(swapRouter); // 0xE5924
    }

    function setManagementFee(uint256 _managementFee) public onlyOwner {
        managementFee = _managementFee;
    }

    function deposit(
        StableInfo calldata _inputStables,
        address _underlyingAsset
    ) external nonReentrant {
        // @note TODO: accounting of user to token and amounts for how much interest should be given based on the amount of time staked
        // for now, we ignore calculating based on time, we just give user the average yield
        // user takes array of stable coins-amount from user
        // algorithm: highest interest is the stable we will swap to
        // based on rates we either swap tokens or not at curve or uniswap v3 (this can be done off chain possibly)
        if (_inputStables.tokenAddress == _underlyingAsset) {
            // deposit tokens into aave for lending
            _supplyToAave(_underlyingAsset, _inputStables.amount);
            // mint StableYieldToken to user of input amount
            _handleMint(msg.sender, _inputStables.amount);
        } else {
            // swap tokens to deposit_underlyingAsset and then deposits these tokens into aave for lending
            uint256 outputAmount = swapInUniswapV3(
                _inputStables.tokenAddress,
                _underlyingAsset,
                _inputStables.amount
            );
            // deposit tokens into aave for lending
            _supplyToAave(_underlyingAsset, outputAmount);
            // mint StableYieldToken to user equal to amount of _underlyingAsset tokens we got from curve
            _handleMint(msg.sender, outputAmount);
        }
    }

    /**
     * @notice User burns their Stable Yield Coin to redeem desired token.
     * @dev Take as much liquidity from lowest APY pools.
     */
    function redeem(
        StableInfo calldata _desiredStableData,
        StableInfo[] calldata _withdrawalData
    ) external {
        // @note TODO: off-chain algorithm:
        // - check APYs + liquidity in pools from aave contracts of deposited tokens of this contract
        _burn(msg.sender, _desiredStableData.amount);
        uint256 sumOutputAmount;
        for (uint8 i = 0; i < _withdrawalData.length; i++) {
            _withdrawFromAave(
                _withdrawalData[i].tokenAddress,
                // TODO: function which calculates how much user should get
                _withdrawalData[i].amount,
                address(this)
            );
            IERC20(_withdrawalData[i].tokenAddress).approve(
                address(0), // @note TODO: router
                _withdrawalData[i].amount
            );

            sumOutputAmount += swapInUniswapV3(
                _withdrawalData[i].tokenAddress,
                _desiredStableData.tokenAddress,
                _withdrawalData[i].amount
            );
        }

        IERC20(_desiredStableData.tokenAddress).transfer(
            msg.sender,
            sumOutputAmount
        );
    }

    function rebalance(address _currentUnderlying, address _newUnderlying)
        external
        onlyOwner
    {
        DataTypes.ReserveData memory reserveData = pool().getReserveData(
            _currentUnderlying
        );

        uint256 aTokenBalance = IERC20(reserveData.aTokenAddress).balanceOf(
            address(this)
        );
        uint256 withdrawnAmount = _withdrawFromAave(
            _currentUnderlying,
            aTokenBalance,
            address(this)
        );
        _supplyToAave(_newUnderlying, withdrawnAmount);
    }

    // view functions

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

    function pool() internal view returns (IPool) {
        return IPool(aavePoolAddressesProvider.getPool());
    }

    function _supplyToAave(address _underlyingAsset, uint256 _amount) internal {
        // Input variables
        address tokenAddress = address(_underlyingAsset);
        uint16 referral = 0;

        // Approve LendingPool contract to move the input tokens
        IERC20(tokenAddress).approve(address(pool()), _amount);

        // Deposit the input tokens
        pool().supply(tokenAddress, _amount, address(this), referral);
    }

    function _withdrawFromAave(
        address _underlyingAsset,
        uint256 _amount,
        address _to
    ) internal returns (uint256 amount) {
        amount = pool().withdraw(_underlyingAsset, _amount, _to);
    }

    function swapInUniswapV3(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 minimalAmount = (_amount * 100) / amountOutMinimumModifier;
        return
            uniswapSwap.swapExactInputSingle(
                _amount,
                _from,
                _to,
                minimalAmount
            );
    }

    function getSwapRouterAddress() public view returns (address) {
        return uniswapRouterAddress;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
