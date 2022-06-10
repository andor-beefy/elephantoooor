// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StableYieldCoin is ERC20("Stable Yield Coin", "SYC") {
    address public optimizer;

    error NotValidOptimizer();

    constructor(address _optimizer) {
        optimizer = _optimizer;
    }

    modifier onlyOptimizer() {
        if (msg.sender == optimizer) revert NotValidOptimizer();
        _;
    }

    function mint(address _account, uint256 _amount) external onlyOptimizer {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOptimizer {
        _burn(_account, _amount);
    }
}
