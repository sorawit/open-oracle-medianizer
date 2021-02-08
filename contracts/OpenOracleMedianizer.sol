pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/math/SafeMath.sol';
import './OpenOraclePriceData.sol';

contract OpenOracleMedianizer {
    using SafeMath for uint;

    address public governor;
    address public pendingGovernor;
    uint public minStalePrice;
    OpenOraclePriceData public priceData;

    address[] public reporters;
    mapping (address => uint) public weights;

    constructor(OpenOraclePriceData _priceData, uint _minStalePrice) public {
        governor = msg.sender;
        priceData = _priceData;
        minStalePrice = _minStalePrice;
    }

    struct Tuple {
        uint price;
        uint weight;
    }

    function repoterCount() external view returns (uint) {
        return reporters.length;
    }

    function price(string memory symbol) external view returns (uint) {
        uint reporterLength = reporters.length;
        uint tupleLength = 0;
        uint totalWeight = 0;
        Tuple[] memory tuples = new Tuple[](reporterLength);
        for (uint i = 0; i < reporterLength; i++) {
            address reporter = reporters[i];
            (uint timestamp, uint value) = priceData.get(reporter, symbol);
            if (timestamp > block.timestamp - minStalePrice) {
                uint weight = weights[reporter];
                tuples[tupleLength].price = value;
                tuples[tupleLength].weight = weight;
                totalWeight = totalWeight.add(weight);
                tupleLength++;
            }
        }
        require(tupleLength != 0, 'no-valid-price-data');
        for (uint i = 0; i < tupleLength-1; i++) {
            for (uint j = 0; j < tupleLength-i-1; j++) {
                if (tuples[j].weight > tuples[j+1].weight) {
                    Tuple memory temp = tuples[i];
                    tuples[i] = tuples[j];
                    tuples[j] = temp;
                }
            }
        }
        uint midWeight = totalWeight / 2;
        uint sumWeight = 0;
        for (uint i = 0; i < tupleLength; i++) {
            sumWeight = sumWeight.add(tuples[i].weight);
            if (sumWeight >= midWeight) {
                return tuples[i].price;
            }
        }
        assert(false);
    }

    function postPrices(bytes[] calldata messages, bytes[] calldata signatures) external {
        require(messages.length == signatures.length, 'inconsistent-length');
        for (uint i = 0; i < messages.length; i++) {
            priceData.put(messages[i], signatures[i]);
        }
    }

    function setReporter(address reporter, uint weight) external {
        require(msg.sender == governor, 'not-governor');
        uint reporterLength = reporters.length;
        for (uint i = 0; i < reporterLength; i++) {
            if (reporters[i] == reporter) {
                weights[reporter] = weight;
                if (weight == 0) {
                    reporters[i] = reporters[reporterLength - 1];
                    reporters.pop();
                }
                return;
            }
        }
        require(weight != 0, 'new-reporter-with-zero-weight');
        reporters.push(reporter);
        weights[reporter] = weight;
    }

    function setPriceData(OpenOraclePriceData _priceData) external {
        require(msg.sender == governor, 'not-governor');
        priceData = _priceData;
    }

    function setMinStalePrice(uint _minStalePrice) external {
        require(msg.sender == governor, 'not-governor');
        minStalePrice = _minStalePrice;
    }

    function changeGovernor(address _pendingGovernor) external {
        require(msg.sender == governor, 'not-governor');
        pendingGovernor = _pendingGovernor;
    }

    function acceptGovernor() external {
        require(msg.sender == pendingGovernor, 'not-pending-governor');
        governor = msg.sender;
        pendingGovernor = address(0);
    }
}
