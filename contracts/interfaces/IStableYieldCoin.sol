// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IStableYieldCoin {
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}