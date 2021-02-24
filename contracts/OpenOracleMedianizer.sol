pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/utils/Address.sol";
import "./OpenOraclePriceData.sol";
import "../interfaces/IAdapter.sol";
import "./Governable.sol";

contract OpenOracleMedianizer is Governable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public minStalePrice;
    OpenOraclePriceData public priceData;

    address[] public reporters;
    mapping(address => uint256) public weights;

    constructor(uint256 _minStalePrice) public {
        governor = msg.sender;
        priceData = new OpenOraclePriceData();
        minStalePrice = _minStalePrice;
    }

    struct Tuple {
        uint256 price;
        uint256 weight;
    }

    function repoterCount() external view returns (uint256) {
        return reporters.length;
    }

    function price(string memory symbol) external view returns (uint256) {
        uint256 reporterLength = reporters.length;
        uint256 tupleLength = 0;
        uint256 totalWeight = 0;
        Tuple[] memory tuples = new Tuple[](reporterLength);
        for (uint256 i = 0; i < reporterLength; i++) {
            address reporter = reporters[i];
            uint256 timestamp;
            uint256 value;
            if (reporter.isContract()) {
                (timestamp, value) = IAdapter(reporter).getPrice(symbol);
            } else {
                (timestamp, value) = priceData.get(reporter, symbol);
            }
            if (timestamp > block.timestamp - minStalePrice) {
                uint256 weight = weights[reporter];
                tuples[tupleLength].price = value;
                tuples[tupleLength].weight = weight;
                totalWeight = totalWeight.add(weight);
                tupleLength++;
            }
        }
        require(tupleLength != 0, "no-valid-price-data");
        for (uint256 i = 0; i < tupleLength - 1; i++) {
            for (uint256 j = 0; j < tupleLength - 1; j++) {
                if (tuples[j].price > tuples[j + 1].price) {
                    Tuple memory temp = tuples[j + 1];
                    tuples[j + 1] = tuples[j];
                    tuples[j] = temp;
                }
            }
        }
        uint256 midWeight = totalWeight / 2;
        uint256 sumWeight = 0;
        for (uint256 i = 0; i < tupleLength; i++) {
            sumWeight = sumWeight.add(tuples[i].weight);
            if (sumWeight >= midWeight) {
                return tuples[i].price;
            }
        }
        assert(false);
    }

    function postSignedPrices(
        bytes[] calldata messages,
        bytes[] calldata signatures
    ) external {
        require(messages.length == signatures.length, "inconsistent-length");
        for (uint256 i = 0; i < messages.length; i++) {
            priceData.put(messages[i], signatures[i]);
        }
    }

    function postPrices(
        string[] calldata keys,
        uint64[] calldata timestamps,
        uint64[] calldata prices
    ) external {
        require(keys.length == timestamps.length, "inconsistent-length");
        require(keys.length == prices.length, "inconsistent-length");
        for (uint256 i = 0; i < keys.length; i++) {
            priceData.putBySender(
                msg.sender,
                timestamps[i],
                keys[i],
                prices[i]
            );
        }
    }

    function setWeight(address reporter, uint256 weight) external onlyGov {
        uint256 reporterLength = reporters.length;
        for (uint256 i = 0; i < reporterLength; i++) {
            if (reporters[i] == reporter) {
                weights[reporter] = weight;
                if (weight == 0) {
                    reporters[i] = reporters[reporterLength - 1];
                    reporters.pop();
                }
                return;
            }
        }
        require(weight != 0, "new-reporter-with-zero-weight");
        reporters.push(reporter);
        weights[reporter] = weight;
    }

    function setPriceData(OpenOraclePriceData _priceData) external onlyGov {
        priceData = _priceData;
    }

    function setMinStalePrice(uint256 _minStalePrice) external onlyGov {
        minStalePrice = _minStalePrice;
    }
}
