// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract UniswapV3Swap {
    // set the pool fee to 0.05%.
    uint24 public constant poolFee = 500;
    ISwapRouter swapRouter;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    /// @notice swapExactInputSingle swaps a fixed amount of tokenInAddress for a maximum possible amount of tokenOutAddress
    /// using the tokenInAddress/tokenOutAddress 0.05% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its tokenInAddress for this function to succeed.
    /// @param _amountIn The exact amount of tokenInAddress that will be swapped for tokenOutAddress.
    /// @param _tokenInAddress Input token address.
    /// @param _tokenOutAddress Output token address.
    /// @param _amountOutMinimum Minimal amount of output tokens that we want to get from the swap, revert otherwise.
    /// @return amountOut The amount of tokenOutAddress received.
    function swapExactInputSingle(
        uint256 _amountIn,
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountOutMinimum
    ) external returns (uint256 amountOut) {
        // Transfer the specified amount of tokenInAddress to this contract.
        TransferHelper.safeTransferFrom(
            _tokenInAddress,
            msg.sender,
            address(this),
            _amountIn
        );

        // Approve the router to spend tokenInAddress.
        TransferHelper.safeApprove(
            _tokenInAddress,
            address(swapRouter),
            _amountIn
        );

        // make sure we get at least minimalAmountOutof our input value back
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenInAddress,
                tokenOut: _tokenOutAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }
}
