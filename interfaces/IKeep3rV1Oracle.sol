pragma solidity ^0.6.10;

interface IKeep3rV1Oracle {
    function WETH() external view returns (address);

    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256);
}
