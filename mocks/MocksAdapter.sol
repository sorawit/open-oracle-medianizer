 // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.10;

import "../interfaces/IAdapter.sol";

contract MockAdapter is IAdapter {
    mapping(string => uint256) prices;

    function getPrice(string memory symbol)
        external
        view
        returns (uint256, uint256) {
            return (now, prices[symbol]);
    }

    function setPrices(string memory symbol, uint256 value) external {
        prices[symbol] = value;
    } 
}
