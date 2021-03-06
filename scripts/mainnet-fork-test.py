import requests
from brownie import (
    accounts,
    chain,
    BandAdapter,
    ChainlinkAdapter,
    Keep3rAdapter,
    OpenOraclePriceData,
    OpenOracleMedianizer,
)
from eth_account import Account, messages
from eth_abi import encode_abi
from eth_utils import keccak

REPORTS = [
    {
        "private_key": "e75a6849442d9b41a088e386cd075187870f154ca65a7adbb0cb6c9071e2ca20",
        "address": "0xeebc30B73Cc6148c9c770cDC356147B147D4BB1F",
    },
    {
        "private_key": "2b7ab5d7f2d5c8feff8a137a5b89661ae38a8ce24df090f3d5138622d83b6b81",
        "address": "0xb479B532FC51602213fa16aDF1F2135B6CCcf3a7",
    },
    {
        "private_key": "cad28bae4e86ebd7c65e69777473914715973ba9915e9cbd0e4611af1ed26f89",
        "address": "0xDa3C562777eEA4f13329c445C380513887cA600B",
    },
    {
        "private_key": "09542fdf3de20809d0b8309acffc56b084347d55dc765c77bb2af1118499b715",
        "address": "0x6CA4EC48c06817A162Da4DaA3c430a62628513ed",
    },
    {
        "private_key": "aa7561b9713ae89218db37b68b5cb668e17cb0bb5ea09d13590797f5535188a2",
        "address": "0xb5D01C78fEA60c4d9b9af69Cc824c1DDf3B3A415",
    },
]


def generate_signature(symbol, timestamp, value, private_key):
    message = encode_abi(
        ["string", "uint64", "string", "uint64"],
        ["prices", int(timestamp), symbol, int(float(value) * 1000000)],
    )
    # // This part prepares "version E" messages, using the EIP-191 standard
    sign_message = messages.encode_defunct(keccak(message))

    # // This part signs any EIP-191-valid message
    signed_message = Account.sign_message(sign_message, private_key=private_key)
    return message, encode_abi(
        ["uint256", "uint256", "uint256"],
        [signed_message.r, signed_message.s, signed_message.v],
    )


def main():
    bandAdapter = accounts[0].deploy(
        BandAdapter, "0xDA7a001b254CD22e46d3eAB04d937489c93174C3"
    )

    chainlinkAdapter = accounts[0].deploy(ChainlinkAdapter)
    chainlinkAdapter.setAggregators(
        ["ETH", "COMP"],
        [
            "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
            "0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5",
        ],
        {"from": accounts[0]},
    )

    keep3rAdapter = accounts[0].deploy(
        Keep3rAdapter, bandAdapter.address, chainlinkAdapter.address
    )
    keep3rAdapter.setTokens(
        ["COMP"],
        ["0xc00e94Cb662C3520282E6f5717214004A7f26888"],
        ["0x73353801921417f465377c8d898c6f4c0270282c"],
        {"from": accounts[0]},
    )

    (bandTimestamp, bandPrice) = bandAdapter.getPrice("COMP")
    (chainlinkTimestamp, chainlinkPrice) = chainlinkAdapter.getPrice("COMP")
    (keep3rTimestamp, keep3rPrice) = keep3rAdapter.getPrice("COMP")

    m = OpenOracleMedianizer.deploy(100 * 86400, {"from": accounts[0]})

    reporter = REPORTS[0]
    timestamp = chain.time()

    coingecko_price = requests.get(
        "https://api.coingecko.com/api/v3/simple/price?ids=compound-governance-token&vs_currencies=usd"
    ).json()["compound-governance-token"]["usd"]
    price_1 = coingecko_price * 1.01
    price_2 = coingecko_price * 0.99

    msg, sig = generate_signature("COMP", timestamp, price_1, reporter["private_key"])
    m.setWeight(reporter["address"], 100, {"from": accounts[0]})
    m.postSignedPrices([msg], [sig])

    m.setWeight(accounts[1], 100, {"from": accounts[0]})
    m.postPrices(["COMP"], [timestamp], [price_2], {"from": accounts[1]})

    m.setWeight(bandAdapter.address, 100, {"from": accounts[0]})
    m.setWeight(chainlinkAdapter.address, 100, {"from": accounts[0]})
    m.setWeight(keep3rAdapter.address, 100, {"from": accounts[0]})

    print(
        f"""
    Manual Feed Price: {price_1}
    Manual2 Feed Price: {price_2}
    Band Price: {bandPrice}
    Chainlink Price: {chainlinkPrice}
    Keep3r Price: {keep3rPrice}
    ---------------------------
    Medianizer Price: {m.price("COMP")}
    """
    )
