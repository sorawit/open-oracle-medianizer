pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/math/SafeMath.sol";
import "../../interfaces/IAdapter.sol";
import "../../interfaces/IAggregatorV3Interface.sol";
import "../Governable.sol";

contract ChainlinkAdapter is Governable, IAdapter {
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;

    mapping(string => address) public aggregators;

    function setAggregators(
        string[] memory _symbols,
        address[] memory _aggregators
    ) external onlyGov {
        require(_symbols.length == _aggregators.length, "inconsistent length");
        for (uint256 idx = 0; idx < _aggregators.length; idx++) {
            aggregators[_symbols[idx]] = _aggregators[idx];
        }
    }

    function getPrice(string memory symbol)
        external
        view
        override
        returns (uint256, uint256)
    {
        AggregatorV3Interface feed = AggregatorV3Interface(aggregators[symbol]);
        (, int256 price, , uint256 timeStamp, ) = feed.latestRoundData();
        uint256 shift = (10**uint256(feed.decimals())).div(1e6);
        return (timeStamp, uint256(price).div(shift));
    }
}
