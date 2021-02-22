from eth_account import Account, messages
from eth_abi import encode_abi
from eth_utils import keccak
from brownie import chain

REPORTS = [
    {
        "private_key": "e75a6849442d9b41a088e386cd075187870f154ca65a7adbb0cb6c9071e2ca20",
        "address": "0xeebc30B73Cc6148c9c770cDC356147B147D4BB1F",
        "prices": {
            "BAT": "0.415700",
            "BTC": "39091.900000",
            "COMP": "481.900000",
            "ETH": "1637.180000",
            "KNC": "1.933000",
            "LINK": "24.682000",
            "ZRX": "1.597200",
        },
    },
    {
        "private_key": "2b7ab5d7f2d5c8feff8a137a5b89661ae38a8ce24df090f3d5138622d83b6b81",
        "address": "0xb479B532FC51602213fa16aDF1F2135B6CCcf3a7",
        "prices": {
            "BAT": "0.415800",
            "BTC": "39092.900000",
            "COMP": "481.000000",
            "ETH": "1637.280000",
            "KNC": "1.934000",
            "LINK": "24.683000",
            "ZRX": "1.598200",
        },
    },
    {
        "private_key": "cad28bae4e86ebd7c65e69777473914715973ba9915e9cbd0e4611af1ed26f89",
        "address": "0xDa3C562777eEA4f13329c445C380513887cA600B",
        "prices": {
            "BAT": "0.415900",
            "BTC": "39093.900000",
            "COMP": "481.100000",
            "ETH": "1637.380000",
            "KNC": "1.935000",
            "LINK": "24.684000",
            "ZRX": "1.599200",
        },
    },
    {
        "private_key": "09542fdf3de20809d0b8309acffc56b084347d55dc765c77bb2af1118499b715",
        "address": "0x6CA4EC48c06817A162Da4DaA3c430a62628513ed",
        "prices": {
            "BAT": "0.415000",
            "BTC": "39094.900000",
            "COMP": "481.200000",
            "ETH": "1637.480000",
            "KNC": "1.936000",
            "LINK": "24.685000",
            "ZRX": "1.590200",
        },
    },
    {
        "private_key": "aa7561b9713ae89218db37b68b5cb668e17cb0bb5ea09d13590797f5535188a2",
        "address": "0xb5D01C78fEA60c4d9b9af69Cc824c1DDf3B3A415",
        "prices": {
            "BAT": "0.415100",
            "BTC": "39095.900000",
            "COMP": "481.300000",
            "ETH": "1637.580000",
            "KNC": "1.937000",
            "LINK": "24.686000",
            "ZRX": "1.591200",
        },
    },
]


def generate_signature(symbol, timestamp, value, private_key):
    message = encode_abi(
        ["string", "uint64", "string", "uint64"], ["prices", int(timestamp), symbol, int(float(value) * 1000000)]
    )
    # // This part prepares "version E" messages, using the EIP-191 standard
    sign_message = messages.encode_defunct(keccak(message))

    # // This part signs any EIP-191-valid message
    signed_message = Account.sign_message(sign_message, private_key=private_key)
    return message, encode_abi(
        ["uint256", "uint256", "uint256"],
        [signed_message.r, signed_message.s, signed_message.v],
    )


def test_weighted_median(a, OpenOraclePriceData, OpenOracleMedianizer):
    p = OpenOraclePriceData.deploy({"from": a[0]})
    m = OpenOracleMedianizer.deploy(p, 100 * 86400, {"from": a[0]})
    timestamp = chain.time()
    for each in REPORTS:
        messages = []
        sigs = []
        for symbol, price in each["prices"].items():
            msg, sig = generate_signature(symbol, timestamp, price, each["private_key"])
            messages.append(msg)
            sigs.append(sig)
        m.postSignedPrices(messages, sigs)
    m.setReporter(REPORTS[0]["address"], 100)
    assert m.repoterCount() == 1
    assert m.price("BTC") == 39091900000
    m.setReporter(REPORTS[1]["address"], 100)
    m.setReporter(REPORTS[2]["address"], 100)
    m.setReporter(REPORTS[3]["address"], 100)
    m.setReporter(REPORTS[4]["address"], 100)
    assert m.repoterCount() == 5
    assert m.price("BTC") == 39093900000
    m.setReporter(REPORTS[3]["address"], 500)
    assert m.repoterCount() == 5
    assert m.price("BTC") == 39094900000
    m.setReporter(REPORTS[3]["address"], 0)
    assert m.repoterCount() == 4
    assert m.price("BTC") == 39092900000


# def test_generate_signature(a, OpenOraclePriceData):
#     p = OpenOraclePriceData.deploy({"from": a[0]})
#     msg, sig = generate_signature("BTC", "1613993483", "39091.900000", PRIVATE_KEYS[0])
#     print(msg.hex(), sig.hex())
#     assert False
