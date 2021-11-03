#!/usr/bin/python3
from brownie import SimpleCollectible, BuyTheDipNFT, accounts, network, config
from metadata import sample_metadata
from scripts.helpful_scripts import get_breed, OPENSEA_FORMAT


dip_metadata_dic = {
    0: "https://ipfs.io/ipfs/QmZeMdpQr6CQK75p55hSHRu9wKueMZYngQ4PYTHsTgskoo?filename=BuyTheDipEmpty.jpg",
    1: "https://ipfs.io/ipfs/QmVVmmaGu7eeASi9YgxAoeAA7BZjwtmiaGcT5hRsTZChVG?filename=BuyTheDipFull.jpg"
}


def main():
    print("Working on " + network.show_active())
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    number_of_btds = btd.tokenCounter()
    print(
        "The number of tokens you've deployed is: "
        + str(number_of_btds)
    )
    for token_id in range(number_of_btds):
        dip_level = btd.requestIdToDipLevel(token_id)
        if not btd.tokenURI(token_id).startswith("https://"):
            print("Setting tokenURI of {}".format(token_id))
            set_tokenURI(token_id, btd,
                         dip_metadata_dic[dip_level])
        else:
            print("Skipping {}, we already set that tokenURI!".format(token_id))


def set_tokenURI(token_id, nft_contract, tokenURI):
    dev = accounts.add(config["wallets"]["from_key"])
    nft_contract.setTokenURI(token_id, tokenURI, {"from": dev})
    print(
        "Awesome! You can view your NFT at {}".format(
            OPENSEA_FORMAT.format(nft_contract.address, token_id)
        )
    )
    print('Please give up to 20 minutes, and hit the "refresh metadata" button')
