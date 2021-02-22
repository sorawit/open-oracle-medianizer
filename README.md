# Compound Weighted Median Oracle

This documentation explains a proposal to build medianizer for Compound oracle. See original discussion [here](https://www.comp.xyz/t/building-a-medianizer/1031).

## Design Goals

TBD

## Specification

The compound medianizer smart contract allows the Compound governance to set the weight of each source. A source can be anything ranging from

1. Price data signed centralized parties/exchanges, following the [Open Price Feed](https://compound.finance/docs/prices) standard.
2. On-chain decentralized exchanges that provide price data. Examples include [Uniswap](http://uniswap.org/), [Sushiswap](https://sushiswap.fi/), or [Balancer](https://medium.com/balancer-protocol/balancer-v2-generalizing-amms-16343c4563ff).
3. On-chain oracle networks that natively provides price data.
4. Indepedent reporters with known Ethereum addresses. Can be psudonymous identities (like MakerDAO's reporters) or people who are well respected by the community.

Compound smart contracts can query for price data by invoking the medianizer's price routine, which is a public view function that takes a symbol string and returns the price value, multiplied by 1000000.

### Methods

setWeight must be called by the Compound governance to set the median weight of the given reporter address. Setting weight to zero removes the reporter from the medianizer.

```solidity
function setWeight(address reporter, uint256 weight) external;
```

price returns the medianized price of the given symbol using the weights set by the governance.

```solidity
function price(string calldata symbol) external view returns (uint256)
```

postSignedPrices can be called permissionlessly by anyone to relay prices signed by reporters. [Specification](https://compound.finance/docs/prices).

```solidity
function postSignedPrices(
  bytes[] calldata messages,
  bytes[] calldata signatures
) external;
```

postPrices can be called directly by a reporter to post prices to the medianizer.

```solidity
function postPrices(
  string[] calldata keys,
  uint64[] calldata timestamps,
  uint256[] calldata prices
) external;
```

## Reference Implementation

Reference implementation is available at https://github.com/sorawit/open-oracle-medianizer under [the MIT License](https://opensource.org/licenses/MIT).
