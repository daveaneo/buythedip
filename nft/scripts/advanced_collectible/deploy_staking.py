#!/usr/bin/python3
from brownie import BuyTheDipNFT, DipStaking, accounts, network, config
from scripts.helpful_scripts import fund_with_link


def main():
    dev = accounts.add(config["wallets"]["from_key"])
    print(network.show_active())
    # publish_source = True if os.getenv("ETHERSCAN_TOKEN") else False # Currently having an issue with this
    publish_source = False

    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]


    # Deploy (call constructor)
    dip_staking = DipStaking.deploy(btd.address,
        {"from": dev},
        publish_source=publish_source,
    )
    # fund_with_link(btd.address)
    return btd
