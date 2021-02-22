// SPDX-License-Identifier: GPL-3.0
// https://github.com/compound-finance/open-oracle/blob/master/contracts/OpenOracleData.sol

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/math/SafeMath.sol";
import "../../interfaces/IKeep3rV1Oracle.sol";
import "../../interfaces/IAdapter.sol";
import "../Governable.sol";

contract Keep3rAdapter is Governable, IAdapter {
    using SafeMath for uint256;
    uint256 amountIn = 1e18;

    IAdapter public chainlinkAdapter;
    IAdapter public bandAdapter;

    mapping(string => address) public tokens;
    mapping(string => address) public keepers;

    constructor(IAdapter _bandAdapter, IAdapter _chainlinkAdapter) public {
        __Governable__init();
        chainlinkAdapter = _chainlinkAdapter;
        bandAdapter = _bandAdapter;
    }

    function setTokens(
        string[] memory _symbols,
        address[] memory _tokens,
        address[] memory _keepers
    ) external onlyGov {
        require(_symbols.length == _tokens.length, "inconsistent length");
        for (uint256 idx = 0; idx < _tokens.length; idx++) {
            tokens[_symbols[idx]] = _tokens[idx];
            keepers[_symbols[idx]] = _keepers[idx];
        }
    }

    function getPrice(string memory symbol)
        external
        view
        override
        returns (uint256, uint256)
    {
        IKeep3rV1Oracle keeper = IKeep3rV1Oracle(keepers[symbol]);
        uint256 keeperPrice =
            keeper.current(tokens[symbol], amountIn, keeper.WETH());

        (uint256 chainlinkTimestamp, uint256 chainlinkPrice) =
            chainlinkAdapter.getPrice("ETH");
        (uint256 bandTimestamp, uint256 bandPrice) =
            chainlinkAdapter.getPrice("ETH");

        uint256 ethPrice = chainlinkPrice.add(bandPrice).div(2);

        uint256 price = keeperPrice.mul(ethPrice).div(1e18);
        return (block.timestamp, price);
    }
}
