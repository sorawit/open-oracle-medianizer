// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.10;

interface IAdapter {
    /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
    /// @param symbol The ERC-20 token symbol to check the value.
    /// @return
    function getPrice(string memory symbol)
        external
        view
        returns (uint256, uint256);
}
