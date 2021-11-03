#!/usr/bin/python3
from brownie import SimpleToken, accounts, network, config
from scripts.helpful_scripts import fund_with_link

def main():
    dev = accounts.add(config["wallets"]["from_key"])
    print(network.show_active())
    # publish_source = True if os.getenv("ETHERSCAN_TOKEN") else False # Currently having an issue with this
    publish_source = False
    inital_supply = 10**18

    # Deploy (call constructor)
    simp = SimpleToken.deploy(
        "Simple Token",
        "Simp",
        inital_supply,
        {"from": dev},
        publish_source=publish_source,
    )
    return simp
