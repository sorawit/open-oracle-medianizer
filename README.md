# Compound Weighted Median Oracle

This documentation explains a proposal to build medianizer for Compound oracle. See original discussion [here](https://www.comp.xyz/t/building-a-medianizer/1031).

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

## Testing on Mainnet Fork

```sh
$ brownie run scripts/adapters.py --network mainnet-fork
Brownie v1.13.1 - Python development framework for Ethereum

CompoundMedianizerProject is the active project.
Running 'scripts/adapters.py::main'...

Transaction sent: 0x7847b1abe35b07bec2517fe6382aff8066d7d21c016d47ced123698ed3f8f16b
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 1
  BandAdapter.constructor confirmed - Block: 11907935   Gas used: 339872 (2.83%)
  BandAdapter deployed at: 0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6

Transaction sent: 0xfa53bb3ec6e713d705e5845d33a6e298bdcf81e75577365a8d8ab8f5ef9dd90d
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 2
  ChainlinkAdapter.constructor confirmed - Block: 11907936   Gas used: 536276 (4.47%)
  ChainlinkAdapter deployed at: 0xE7eD6747FaC5360f88a2EFC03E00d25789F69291

Transaction sent: 0xcbb330a99421e2fa15a29a3aefe8385b8068130b37a2ae6af55515c13fb2e391
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 3
  ChainlinkAdapter.setAggregators confirmed - Block: 11907937   Gas used: 39071 (0.33%)

Transaction sent: 0xea3e50fcf34298b517075fd08c7e1cf8d467caeb7d0785e1128d98b845de373d
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 4
  Keep3rAdapter.constructor confirmed - Block: 11907938   Gas used: 734610 (6.12%)
  Keep3rAdapter deployed at: 0xe0aA552A10d7EC8760Fc6c246D391E698a82dDf9

Transaction sent: 0x3cd55ea0ce2bd1fc56811e1bf346c798831d84d51abf38429f16f36201c04099
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 5
  Keep3rAdapter.setTokens confirmed - Block: 11907939   Gas used: 38894 (0.32%)

Transaction sent: 0x808d83f6827a6ca9c6672b54a1f1dd9c72be8c29f8d3711d66154f0a1280c47f
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 6
  OpenOracleMedianizer.constructor confirmed - Block: 11907940   Gas used: 1821910 (15.18%)
  OpenOracleMedianizer deployed at: 0x9E4c14403d7d9A8A782044E86a93CAE09D7B2ac9

Transaction sent: 0x40f652e3e8d5f8a78a07ac95e2a712bbfcfed0bea253783b32ee26890902b6af
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 7
  OpenOracleMedianizer.setWeight confirmed - Block: 11907941   Gas used: 40416 (0.34%)

Transaction sent: 0x969d8f212cca24a916af1cc555698cf00400eea7c88f047bac4a39aeed1de084
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 8
  OpenOracleMedianizer.postSignedPrices confirmed - Block: 11907942   Gas used: 47206 (0.39%)

Transaction sent: 0x0fa40dd6f2bd1fbb67fd755d6829ee5a28861618629cfa2ada660100a388f584
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 9
  OpenOracleMedianizer.setWeight confirmed - Block: 11907943   Gas used: 42207 (0.35%)

Transaction sent: 0xfee886450338152fd0a62b85bf0418d194bc536c9e9044aae0ec0906473e0f3e
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 5
  OpenOracleMedianizer.postPrices confirmed - Block: 11907944   Gas used: 40370 (0.34%)

Transaction sent: 0x029fe710a7eb35d21fead28c436a6bfd62b8cd3d88f3c90b37fb426ac89a1819
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 10
  OpenOracleMedianizer.setWeight confirmed - Block: 11907945   Gas used: 43998 (0.37%)

Transaction sent: 0x7971b4acc315e739d5651f227002d6a4b5e1ae875a2002c7d61764458f214680
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 11
  OpenOracleMedianizer.setWeight confirmed - Block: 11907946   Gas used: 45777 (0.38%)

Transaction sent: 0x6ebd28c08cd36504d59f52c4364af55803bff6b77523fdc0663f481fe854c460
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 12
  OpenOracleMedianizer.setWeight confirmed - Block: 11907947   Gas used: 47580 (0.40%)


    Manual Feed Price: 445870000
    Manual2 Feed Price: 447870000
    Band Price: 431903300
    Chainlink Price: 439419100
    Keep3r Price: 435356583
    ---------------------------
    Medianizer Price: 439419100
```

## Reference Implementation

Reference implementation is available at https://github.com/sorawit/open-oracle-medianizer under [the MIT License](https://opensource.org/licenses/MIT).
