pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../interfaces/IAdapter.sol";
import "../../interfaces/IStdReference.sol";
import "../Governable.sol";

contract BandAdapter is Governable, IAdapter {
    IStdReference ref;

    constructor(IStdReference _ref) public {
        ref = _ref;
    }

    function setRef(IStdReference _ref) external onlyGov {
        ref = _ref;
    }

    function getPrice(string memory symbol)
        external
        view
        override
        returns (uint256, uint256)
    {
        IStdReference.ReferenceData memory data =
            ref.getReferenceData(symbol, "USD");
        return (data.lastUpdatedBase, data.rate / 1e12);
    }
}
